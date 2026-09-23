import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../../domain/models/book.dart';
import '../../domain/models/reading_status.dart';
import '../providers/library_provider.dart';
import '../widgets/book_cover.dart';
import 'scanner_screen.dart';

class BookFormScreen extends StatefulWidget {
  const BookFormScreen({this.book, super.key});
  final Book? book;

  @override
  State<BookFormScreen> createState() => _BookFormScreenState();
}

class _BookFormScreenState extends State<BookFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _fields;
  late ReadingStatus _status;
  bool _seriesSequential = false;
  bool _busy = false;
  String _localCoverPath = '';
  String _summaryHint = 'ISBN sorgusunda yalnız Türkçe hülasat kabul edilir.';

  bool get _editing => widget.book != null;

  @override
  void initState() {
    super.initState();
    final book = widget.book;
    String value(Object? input) => input == null || input == 0 ? '' : '$input';
    _fields = {
      'isbn': TextEditingController(text: book?.isbn ?? ''),
      'title': TextEditingController(text: book?.title ?? ''),
      'subtitle': TextEditingController(text: book?.subtitle ?? ''),
      'author': TextEditingController(text: book?.author ?? ''),
      'translator': TextEditingController(text: book?.translator ?? ''),
      'summary': TextEditingController(text: book?.summary ?? ''),
      'publisher': TextEditingController(text: book?.publisher ?? ''),
      'category': TextEditingController(text: book?.category ?? ''),
      'year': TextEditingController(text: value(book?.publicationYear)),
      'firstYear': TextEditingController(text: value(book?.firstPublishYear)),
      'pages': TextEditingController(text: value(book?.pageCount)),
      'cover': TextEditingController(text: book?.coverUrl ?? ''),
      'series': TextEditingController(text: book?.series ?? ''),
      'seriesOrder': TextEditingController(text: value(book?.seriesOrder)),
      'previousTitle': TextEditingController(text: book?.previousTitle ?? ''),
      'currentPage': TextEditingController(text: value(book?.currentPage)),
      'review': TextEditingController(text: book?.review ?? ''),
      'rating': TextEditingController(text: value(book?.rating)),
    };
    _status = book?.status ?? ReadingStatus.wantToRead;
    _seriesSequential = book?.seriesSequential ?? false;
    _localCoverPath = book?.localCoverPath ?? '';
  }

  @override
  void dispose() {
    for (final controller in _fields.values) {
      controller.dispose();
    }
    super.dispose();
  }

  int _int(String key) => int.tryParse(_fields[key]!.text.trim()) ?? 0;

  Book get _preview {
    final now = DateTime.now();
    return Book(
      id: widget.book?.id ?? '',
      isbn: _fields['isbn']!.text,
      title: _fields['title']!.text,
      coverUrl: _fields['cover']!.text,
      localCoverPath: _localCoverPath,
      createdAt: widget.book?.createdAt ?? now,
      updatedAt: now,
    );
  }

  Future<void> _scan() async {
    final isbn = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const ScannerScreen()),
    );
    if (isbn == null || !mounted) return;
    _fields['isbn']!.text = isbn;
    await _lookup();
  }

  Future<void> _lookup() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _summaryHint = 'Türkçe hülasat ve kapak aranıyor…';
    });
    try {
      final provider = context.read<LibraryProvider>();
      final book = await provider.lookup(_fields['isbn']!.text, editingId: widget.book?.id);
      if (!mounted) return;
      _fields['isbn']!.text = book.isbn;
      _fields['title']!.text = book.title;
      _fields['subtitle']!.text = book.subtitle;
      _fields['author']!.text = book.author;
      _fields['publisher']!.text = book.publisher;
      _fields['category']!.text = book.category;
      _fields['year']!.text = book.publicationYear == 0 ? '' : '${book.publicationYear}';
      _fields['firstYear']!.text = book.firstPublishYear == 0 ? '' : '${book.firstPublishYear}';
      _fields['pages']!.text = book.pageCount == 0 ? '' : '${book.pageCount}';
      _fields['cover']!.text = book.coverUrl;
      _fields['summary']!.text = book.summary;
      setState(() => _summaryHint = 'Türkçe hülasat katalog kayıtlarından getirildi.');
    } on DuplicateBookException catch (error) {
      _message('Bu ISBN zaten kütüphanede kayıtlı: ${error.book.title}');
      setState(() => _summaryHint = 'Mükerrer kayıt engellendi.');
    } catch (error) {
      _message(error.toString().replaceFirst('BookLookupException: ', ''));
      setState(() => _summaryHint = 'Bilgileri elle girebilirsiniz.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickCover() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 900,
      imageQuality: 78,
    );
    if (picked == null) return;
    final directory = await getApplicationDocumentsDirectory();
    final covers = Directory(path.join(directory.path, 'covers'));
    if (!await covers.exists()) await covers.create(recursive: true);
    final destination = path.join(covers.path, '${DateTime.now().microsecondsSinceEpoch}${path.extension(picked.path)}');
    await File(picked.path).copy(destination);
    if (mounted) setState(() => _localCoverPath = destination);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _busy) return;
    setState(() => _busy = true);
    final now = DateTime.now();
    final old = widget.book;
    final book = Book(
      id: old?.id ?? context.read<LibraryProvider>().newId(),
      isbn: _fields['isbn']!.text.trim(),
      title: _fields['title']!.text.trim(),
      subtitle: _fields['subtitle']!.text.trim(),
      author: _fields['author']!.text.trim(),
      translator: _fields['translator']!.text.trim(),
      publisher: _fields['publisher']!.text.trim(),
      category: _fields['category']!.text.trim(),
      publicationYear: _int('year'),
      firstPublishYear: _int('firstYear'),
      pageCount: _int('pages'),
      currentPage: _editing ? _int('currentPage') : 0,
      coverUrl: _fields['cover']!.text.trim(),
      localCoverPath: _localCoverPath,
      summary: _fields['summary']!.text.trim(),
      review: _editing ? _fields['review']!.text.trim() : '',
      rating: _editing ? _int('rating').clamp(0, 5).toInt() : 0,
      status: _editing ? _status : ReadingStatus.wantToRead,
      series: _fields['series']!.text.trim(),
      seriesOrder: _int('seriesOrder'),
      previousTitle: _fields['previousTitle']!.text.trim(),
      seriesSequential: _seriesSequential,
      createdAt: old?.createdAt ?? now,
      updatedAt: now,
    );
    try {
      await context.read<LibraryProvider>().saveBook(book);
      if (!mounted) return;
      Navigator.pop(context, book);
    } on DuplicateBookException catch (error) {
      _message('Bu ISBN zaten kütüphanede kayıtlı: ${error.book.title}');
    } catch (error) {
      _message('Eser kaydedilemedi: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _message(String value) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(_editing ? 'Eseri Düzenle' : 'Yeni Eser Kaydı'),
        leading: IconButton(icon: const Icon(Icons.close), tooltip: 'Vazgeç', onPressed: () => Navigator.pop(context)),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 110),
          children: [
            Text('ISBN-10 / ISBN-13', style: theme.textTheme.labelLarge),
            const SizedBox(height: 7),
            TextFormField(
              controller: _fields['isbn'],
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(prefixIcon: Icon(Icons.numbers), hintText: '978…'),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.tonalIcon(onPressed: _busy ? null : _lookup, icon: const Icon(Icons.auto_awesome), label: const Text('Otomatik bul')),
                FilledButton.icon(onPressed: _busy ? null : _scan, icon: const Icon(Icons.qr_code_scanner), label: const Text('Barkod okut')),
              ],
            ),
            const SizedBox(height: 15),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    BookCover(_preview, width: 72, height: 102),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_preview.coverUrl.isEmpty && _localCoverPath.isEmpty ? 'Kapak önizlemesi' : 'Kapak hazır', style: theme.textTheme.titleMedium),
                          const SizedBox(height: 5),
                          const Text('Katalog kapağını kontrol edin veya cihazınızdan ekleyin.'),
                          TextButton.icon(onPressed: _pickCover, icon: const Icon(Icons.add_photo_alternate_outlined), label: const Text('Manuel kapak ekle')),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            _field('title', 'İsm-i Eser *', required: true),
            _field('subtitle', 'Alt başlık'),
            _two(_field('author', 'Müellif'), _field('translator', 'Mütercim')),
            Card(
              color: const Color(0xFFF1F7F3),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Hülasat-ül Eser', style: theme.textTheme.labelLarge),
                    const SizedBox(height: 7),
                    TextFormField(controller: _fields['summary'], minLines: 5, maxLines: 10, decoration: const InputDecoration(hintText: 'Eserin Türkçe konusu ve kısa hülasası')),
                    const SizedBox(height: 7),
                    Text(_summaryHint, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            _two(_field('publisher', 'Naşir / Tab’hane'), _field('category', 'Çeşit / Tür')),
            _two(_field('year', 'Zaman-ı Tab', number: true), _field('firstYear', 'İlk çıkış yılı', number: true)),
            _field('pages', 'Sayfa sayısı', number: true),
            _two(_field('series', 'Dizi / Seri'), _field('seriesOrder', 'Serideki sıra', number: true)),
            _field('previousTitle', 'Önceki kitabın adı'),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: _seriesSequential,
              onChanged: (value) => setState(() => _seriesSequential = value),
              title: const Text('Hikâye önceki kitaba doğrudan bağlı'),
              subtitle: const Text('Mütalaaya başlanırken sıra uyarısı gösterilir.'),
            ),
            if (_editing) ...[
              const Divider(height: 36),
              Text('Mütalaa Bilgileri', style: theme.textTheme.titleLarge),
              const SizedBox(height: 12),
              _field('currentPage', 'Bulunduğum sayfa', number: true),
              DropdownButtonFormField<ReadingStatus>(
                value: _status,
                decoration: const InputDecoration(labelText: 'Mütalaa seviyesi'),
                items: ReadingStatus.values.map((value) => DropdownMenuItem(value: value, child: Text(value.label))).toList(),
                onChanged: (value) => setState(() => _status = value ?? _status),
              ),
              const SizedBox(height: 12),
              _field('rating', 'Puan (0–5)', number: true),
              _field('review', 'Mütalaa / Tahlil', lines: 5),
            ],
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 12),
          decoration: const BoxDecoration(color: Color(0xFFFFFEFA), boxShadow: [BoxShadow(color: Color(0x22000000), blurRadius: 16)]),
          child: Row(
            children: [
              Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Vazgeç'))),
              const SizedBox(width: 10),
              Expanded(flex: 2, child: FilledButton.icon(onPressed: _busy ? null : _save, icon: _busy ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save_outlined), label: const Text('Eseri kaydet'))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(String key, String label, {bool required = false, bool number = false, int lines = 1}) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          controller: _fields[key],
          keyboardType: number ? TextInputType.number : (lines > 1 ? TextInputType.multiline : TextInputType.text),
          minLines: lines,
          maxLines: lines,
          decoration: InputDecoration(labelText: label),
          validator: required ? (value) => value == null || value.trim().isEmpty ? 'Bu alan gereklidir.' : null : null,
        ),
      );

  Widget _two(Widget first, Widget second) => LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 600) return Column(children: [first, second]);
          return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: first), const SizedBox(width: 12), Expanded(child: second)]);
        },
      );
}
