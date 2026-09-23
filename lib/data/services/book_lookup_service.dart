import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/utils/isbn.dart';
import '../../domain/models/book.dart';

class BookLookupException implements Exception {
  const BookLookupException(this.message);
  final String message;
  @override
  String toString() => message;
}

class BookLookupService {
  BookLookupService({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;

  Future<Book> lookup(String input, {required String id}) async {
    final isbn = Isbn.normalize(input);
    if (!Isbn.isValid(isbn)) {
      throw const BookLookupException('ISBN numarası veya kontrol basamağı geçersiz.');
    }
    final google = await _googleByIsbn(isbn, id: id);
    final book = google ?? await _openLibrary(isbn, id: id);
    if (book == null) {
      throw const BookLookupException('Bu ISBN kataloglarda bulunamadı.');
    }
    final summary = await _turkishSummary(book);
    return book.copyWith(summary: summary);
  }

  Future<Map<String, dynamic>?> _json(Uri uri) async {
    final response = await _client.get(uri).timeout(const Duration(seconds: 14));
    if (response.statusCode == 404) return null;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw const BookLookupException('Kitap kataloğuna şu anda ulaşılamıyor.');
    }
    return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
  }

  Future<Book?> _googleByIsbn(String isbn, {required String id}) async {
    final uri = Uri.https('www.googleapis.com', '/books/v1/volumes', {
      'q': 'isbn:$isbn',
      'maxResults': '1',
    });
    final data = await _json(uri);
    final items = data?['items'] as List<dynamic>?;
    if (items == null || items.isEmpty) return null;
    final info = (items.first as Map<String, dynamic>)['volumeInfo'] as Map<String, dynamic>?;
    if (info == null || '${info['title'] ?? ''}'.trim().isEmpty) return null;
    final now = DateTime.now();
    final images = info['imageLinks'] as Map<String, dynamic>? ?? const {};
    return Book(
      id: id,
      isbn: isbn,
      title: '${info['title'] ?? ''}',
      subtitle: '${info['subtitle'] ?? ''}',
      author: ((info['authors'] as List<dynamic>?) ?? const []).join(', '),
      publisher: '${info['publisher'] ?? ''}',
      category: ((info['categories'] as List<dynamic>?) ?? const []).join(', '),
      publicationYear: _year('${info['publishedDate'] ?? ''}'),
      pageCount: _number(info['pageCount']),
      coverUrl: '${images['thumbnail'] ?? images['smallThumbnail'] ?? ''}'.replaceFirst('http:', 'https:'),
      summary: _plain('${info['description'] ?? ''}'),
      createdAt: now,
      updatedAt: now,
    );
  }

  Future<Book?> _openLibrary(String isbn, {required String id}) async {
    final data = await _json(Uri.https('openlibrary.org', '/isbn/$isbn.json'));
    if (data == null || '${data['title'] ?? ''}'.isEmpty) return null;
    var author = '';
    final authors = data['authors'] as List<dynamic>?;
    if (authors != null && authors.isNotEmpty) {
      final key = '${(authors.first as Map<String, dynamic>)['key'] ?? ''}';
      if (key.startsWith('/authors/')) {
        try {
          final person = await _json(Uri.https('openlibrary.org', '$key.json'));
          author = '${person?['name'] ?? ''}';
        } catch (_) {}
      }
    }
    final covers = data['covers'] as List<dynamic>?;
    final cover = covers == null || covers.isEmpty
        ? ''
        : 'https://covers.openlibrary.org/b/id/${covers.first}-M.jpg';
    final now = DateTime.now();
    return Book(
      id: id,
      isbn: isbn,
      title: '${data['title'] ?? ''}',
      subtitle: '${data['subtitle'] ?? ''}',
      author: author,
      publisher: ((data['publishers'] as List<dynamic>?) ?? const []).join(', '),
      publicationYear: _year('${data['publish_date'] ?? ''}'),
      pageCount: _number(data['number_of_pages']),
      coverUrl: cover,
      summary: _plain(_description(data['description'])),
      createdAt: now,
      updatedAt: now,
    );
  }

  Future<String> _turkishSummary(Book book) async {
    if (_isTurkish(book.summary)) return _plain(book.summary);
    try {
      final query = 'intitle:"${book.title}"${book.author.isEmpty ? '' : ' inauthor:"${book.author.split(',').first}"'}';
      final data = await _json(Uri.https('www.googleapis.com', '/books/v1/volumes', {
        'q': query,
        'langRestrict': 'tr',
        'maxResults': '10',
      }));
      for (final item in (data?['items'] as List<dynamic>?) ?? const []) {
        final info = (item as Map<String, dynamic>)['volumeInfo'] as Map<String, dynamic>?;
        final value = _plain('${info?['description'] ?? ''}');
        if (_isTurkish(value)) return value;
      }
    } catch (_) {}
    try {
      final search = await _json(Uri.https('tr.wikipedia.org', '/w/api.php', {
        'action': 'query',
        'format': 'json',
        'list': 'search',
        'srsearch': '${book.title} ${book.author}'.trim(),
        'srlimit': '2',
        'origin': '*',
      }));
      final results = ((search?['query'] as Map<String, dynamic>?)?['search'] as List<dynamic>?) ?? const [];
      if (results.isNotEmpty) {
        final title = '${(results.first as Map<String, dynamic>)['title'] ?? ''}';
        final extract = await _json(Uri.https('tr.wikipedia.org', '/w/api.php', {
          'action': 'query',
          'format': 'json',
          'prop': 'extracts|pageprops',
          'titles': title,
          'redirects': '1',
          'exintro': '1',
          'explaintext': '1',
          'exchars': '1600',
          'origin': '*',
        }));
        final pages = ((extract?['query'] as Map<String, dynamic>?)?['pages'] as Map<String, dynamic>?)?.values;
        if (pages != null && pages.isNotEmpty) {
          final page = pages.first as Map<String, dynamic>;
          final text = _plain('${page['extract'] ?? ''}');
          if (page['pageprops'] == null && _isTurkish(text)) return text;
        }
      }
    } catch (_) {}
    final facts = <String>[];
    if (book.author.isNotEmpty) facts.add('${book.author} tarafından kaleme alınmıştır');
    if (book.category.isNotEmpty) facts.add('${book.category} türündedir');
    if (book.publisher.isNotEmpty) facts.add('${book.publisher} tarafından yayımlanmıştır');
    if (book.publicationYear > 0) facts.add('${book.publicationYear} tarihli baskısı katalogda kayıtlıdır');
    return facts.isEmpty
        ? '${book.title} için doğrulanmış Türkçe konu özeti bulunamadı.'
        : '${book.title}, ${facts.join('; ')}.';
  }

  static int _number(Object? value) => value is num ? value.toInt() : int.tryParse('$value') ?? 0;
  static int _year(String value) => int.tryParse(RegExp(r'(18|19|20)\d{2}').firstMatch(value)?.group(0) ?? '') ?? 0;
  static String _description(Object? value) => value is Map ? '${value['value'] ?? ''}' : '${value ?? ''}';
  static String _plain(String value) => value
      .replaceAll(RegExp(r'<[^>]*>'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  static bool _isTurkish(String value) {
    final text = _plain(value).toLowerCase();
    if (text.length >= 8 && RegExp(r'[çğıöşü]').hasMatch(text)) return true;
    if (text.length < 24) return false;
    const words = {'bir', 'bu', 've', 'ile', 'için', 'olan', 'olarak', 'kitap', 'eser', 'yazar', 'roman', 'hikâye', 'hayat', 'insan', 'kendi', 'daha', 'sonra'};
    return text.split(RegExp(r'[^a-zâîû]+')).where(words.contains).length >= 3;
  }
}

