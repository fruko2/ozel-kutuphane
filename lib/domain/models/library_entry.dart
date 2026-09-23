enum EntryKind { quote, note }

class LibraryEntry {
  const LibraryEntry({
    required this.id,
    required this.bookId,
    required this.kind,
    required this.content,
    required this.createdAt,
    this.pageNumber = 0,
  });

  final String id;
  final String bookId;
  final EntryKind kind;
  final int pageNumber;
  final String content;
  final DateTime createdAt;

  Map<String, Object?> toMap() => {
        'id': id,
        'book_id': bookId,
        'kind': kind.name,
        'page_number': pageNumber,
        'content': content,
        'created_at': createdAt.toUtc().toIso8601String(),
      };

  factory LibraryEntry.fromMap(Map<String, Object?> map) => LibraryEntry(
        id: map['id'] as String,
        bookId: map['book_id'] as String,
        kind: map['kind'] == 'note' ? EntryKind.note : EntryKind.quote,
        pageNumber: map['page_number'] as int? ?? 0,
        content: map['content'] as String? ?? '',
        createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
      );
}

