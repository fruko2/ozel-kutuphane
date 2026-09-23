import 'reading_status.dart';

class Book {
  const Book({
    required this.id,
    required this.title,
    this.isbn = '',
    this.subtitle = '',
    this.author = '',
    this.translator = '',
    this.publisher = '',
    this.category = '',
    this.publicationYear = 0,
    this.firstPublishYear = 0,
    this.pageCount = 0,
    this.currentPage = 0,
    this.coverUrl = '',
    this.localCoverPath = '',
    this.summary = '',
    this.review = '',
    this.rating = 0,
    this.status = ReadingStatus.wantToRead,
    this.series = '',
    this.seriesOrder = 0,
    this.previousTitle = '',
    this.seriesSequential = false,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String isbn;
  final String title;
  final String subtitle;
  final String author;
  final String translator;
  final String publisher;
  final String category;
  final int publicationYear;
  final int firstPublishYear;
  final int pageCount;
  final int currentPage;
  final String coverUrl;
  final String localCoverPath;
  final String summary;
  final String review;
  final int rating;
  final ReadingStatus status;
  final String series;
  final int seriesOrder;
  final String previousTitle;
  final bool seriesSequential;
  final DateTime createdAt;
  final DateTime updatedAt;

  double get progress => pageCount <= 0 ? 0 : (currentPage / pageCount).clamp(0, 1).toDouble();

  Book copyWith({
    String? id,
    String? isbn,
    String? title,
    String? subtitle,
    String? author,
    String? translator,
    String? publisher,
    String? category,
    int? publicationYear,
    int? firstPublishYear,
    int? pageCount,
    int? currentPage,
    String? coverUrl,
    String? localCoverPath,
    String? summary,
    String? review,
    int? rating,
    ReadingStatus? status,
    String? series,
    int? seriesOrder,
    String? previousTitle,
    bool? seriesSequential,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Book(
        id: id ?? this.id,
        isbn: isbn ?? this.isbn,
        title: title ?? this.title,
        subtitle: subtitle ?? this.subtitle,
        author: author ?? this.author,
        translator: translator ?? this.translator,
        publisher: publisher ?? this.publisher,
        category: category ?? this.category,
        publicationYear: publicationYear ?? this.publicationYear,
        firstPublishYear: firstPublishYear ?? this.firstPublishYear,
        pageCount: pageCount ?? this.pageCount,
        currentPage: currentPage ?? this.currentPage,
        coverUrl: coverUrl ?? this.coverUrl,
        localCoverPath: localCoverPath ?? this.localCoverPath,
        summary: summary ?? this.summary,
        review: review ?? this.review,
        rating: rating ?? this.rating,
        status: status ?? this.status,
        series: series ?? this.series,
        seriesOrder: seriesOrder ?? this.seriesOrder,
        previousTitle: previousTitle ?? this.previousTitle,
        seriesSequential: seriesSequential ?? this.seriesSequential,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'isbn': isbn,
        'title': title,
        'subtitle': subtitle,
        'author': author,
        'translator': translator,
        'publisher': publisher,
        'category': category,
        'publication_year': publicationYear,
        'first_publish_year': firstPublishYear,
        'page_count': pageCount,
        'current_page': currentPage,
        'cover_url': coverUrl,
        'local_cover_path': localCoverPath,
        'summary': summary,
        'review': review,
        'rating': rating,
        'reading_status': status.dbValue,
        'series': series,
        'series_order': seriesOrder,
        'previous_title': previousTitle,
        'series_sequential': seriesSequential ? 1 : 0,
        'created_at': createdAt.toUtc().toIso8601String(),
        'updated_at': updatedAt.toUtc().toIso8601String(),
      };

  Map<String, Object?> toCloudMap() => {
        'id': id,
        'isbn': isbn,
        'title': title,
        'subtitle': subtitle,
        'author': author,
        'translator': translator,
        'publisher': publisher,
        'category': category,
        'year': publicationYear,
        'firstPublishYear': firstPublishYear,
        'pageCount': pageCount,
        'currentPage': currentPage,
        'cover': coverUrl,
        'summary': summary,
        'review': review,
        'rating': rating,
        'status': status.dbValue,
        'series': series,
        'seriesOrder': seriesOrder,
        'previousTitle': previousTitle,
        'seriesSequential': seriesSequential,
        'inLibrary': true,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'updatedAt': updatedAt.toUtc().toIso8601String(),
      };

  factory Book.fromMap(Map<String, Object?> map) => Book(
        id: map['id'] as String,
        isbn: map['isbn'] as String? ?? '',
        title: map['title'] as String? ?? '',
        subtitle: map['subtitle'] as String? ?? '',
        author: map['author'] as String? ?? '',
        translator: map['translator'] as String? ?? '',
        publisher: map['publisher'] as String? ?? '',
        category: map['category'] as String? ?? '',
        publicationYear: map['publication_year'] as int? ?? 0,
        firstPublishYear: map['first_publish_year'] as int? ?? 0,
        pageCount: map['page_count'] as int? ?? 0,
        currentPage: map['current_page'] as int? ?? 0,
        coverUrl: map['cover_url'] as String? ?? '',
        localCoverPath: map['local_cover_path'] as String? ?? '',
        summary: map['summary'] as String? ?? '',
        review: map['review'] as String? ?? '',
        rating: map['rating'] as int? ?? 0,
        status: ReadingStatusLabel.fromDb(map['reading_status'] as String?),
        series: map['series'] as String? ?? '',
        seriesOrder: map['series_order'] as int? ?? 0,
        previousTitle: map['previous_title'] as String? ?? '',
        seriesSequential: (map['series_sequential'] as int? ?? 0) == 1,
        createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
        updatedAt: DateTime.tryParse(map['updated_at'] as String? ?? '') ?? DateTime.now(),
      );

  factory Book.fromCloudMap(Map<String, dynamic> map) {
    int number(Object? value) => value is num ? value.toInt() : int.tryParse('$value') ?? 0;
    final now = DateTime.now();
    return Book(
      id: '${map['id'] ?? ''}',
      isbn: '${map['isbn'] ?? ''}',
      title: '${map['title'] ?? ''}',
      subtitle: '${map['subtitle'] ?? ''}',
      author: '${map['author'] ?? ''}',
      translator: '${map['translator'] ?? ''}',
      publisher: '${map['publisher'] ?? ''}',
      category: '${map['category'] ?? ''}',
      publicationYear: number(map['year']),
      firstPublishYear: number(map['firstPublishYear']),
      pageCount: number(map['pageCount']),
      currentPage: number(map['currentPage']),
      coverUrl: '${map['cover'] ?? ''}',
      summary: '${map['summary'] ?? ''}',
      review: '${map['review'] ?? ''}',
      rating: number(map['rating']),
      status: ReadingStatusLabel.fromDb('${map['status'] ?? ''}'),
      series: '${map['series'] ?? ''}',
      seriesOrder: number(map['seriesOrder']),
      previousTitle: '${map['previousTitle'] ?? ''}',
      seriesSequential: map['seriesSequential'] == true,
      createdAt: DateTime.tryParse('${map['createdAt'] ?? ''}') ?? now,
      updatedAt: DateTime.tryParse('${map['updatedAt'] ?? ''}') ?? now,
    );
  }
}
