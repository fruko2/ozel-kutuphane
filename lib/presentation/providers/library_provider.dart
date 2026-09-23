import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../core/utils/isbn.dart';
import '../../data/database/app_database.dart';
import '../../data/services/auth_sync_service.dart';
import '../../data/services/book_lookup_service.dart';
import '../../domain/models/book.dart';
import '../../domain/models/book_loan.dart';
import '../../domain/models/library_entry.dart';
import '../../domain/models/reading_status.dart';

class DuplicateBookException implements Exception {
  const DuplicateBookException(this.book);
  final Book book;
}

class LibraryProvider extends ChangeNotifier {
  LibraryProvider({
    required AppDatabase database,
    required BookLookupService lookupService,
    required AuthSyncService authSync,
  })  : _database = database,
        _lookupService = lookupService,
        _authSync = authSync;

  final AppDatabase _database;
  final BookLookupService _lookupService;
  final AuthSyncService _authSync;
  final _uuid = const Uuid();

  List<Book> books = const [];
  List<BookLoan> loans = const [];
  bool loading = true;
  String search = '';
  ReadingStatus? statusFilter;
  String grouping = 'added';

  AuthSyncService get authSync => _authSync;
  String newId() => _uuid.v4();

  Future<void> initialize() async {
    await reload();
  }

  Future<void> reload() async {
    loading = true;
    notifyListeners();
    books = await _database.allBooks();
    loans = await _database.allLoans();
    loading = false;
    notifyListeners();
  }

  List<Book> get visibleBooks {
    final query = search.trim().toLowerCase();
    final result = books.where((book) {
      final matchesStatus = statusFilter == null || book.status == statusFilter;
      final haystack = '${book.title} ${book.author} ${book.isbn} ${book.category}'.toLowerCase();
      return matchesStatus && haystack.contains(query);
    }).toList();
    switch (grouping) {
      case 'author':
        result.sort((a, b) => _tr(a.author).compareTo(_tr(b.author)) != 0
            ? _tr(a.author).compareTo(_tr(b.author))
            : _bookYear(a).compareTo(_bookYear(b)));
        break;
      case 'category':
        result.sort((a, b) => _tr(a.category).compareTo(_tr(b.category)));
        break;
      case 'year':
        result.sort((a, b) => _bookYear(a).compareTo(_bookYear(b)));
        break;
      default:
        result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    return result;
  }

  void setSearch(String value) {
    search = value;
    notifyListeners();
  }

  void setStatusFilter(ReadingStatus? value) {
    statusFilter = value;
    notifyListeners();
  }

  void setGrouping(String value) {
    grouping = value;
    notifyListeners();
  }

  Future<Book> lookup(String isbn, {String? editingId}) async {
    final normalized = Isbn.normalize(isbn);
    final duplicate = await _database.bookByIsbn(normalized, excludingId: editingId);
    if (duplicate != null) throw DuplicateBookException(duplicate);
    return _lookupService.lookup(normalized, id: editingId ?? newId());
  }

  Future<void> saveBook(Book book) async {
    final normalized = Isbn.normalize(book.isbn);
    final duplicate = await _database.bookByIsbn(normalized, excludingId: book.id);
    if (duplicate != null) throw DuplicateBookException(duplicate);
    await _database.saveBook(book.copyWith(isbn: normalized, updatedAt: DateTime.now()));
    await reload();
    await _syncQuietly();
  }

  Future<void> deleteBook(Book book) async {
    await _database.deleteBook(book.id);
    await reload();
    await _syncQuietly();
  }

  Future<List<LibraryEntry>> entriesFor(String bookId) => _database.entriesFor(bookId);
  Future<BookLoan?> activeLoanFor(String bookId) => _database.activeLoanFor(bookId);

  Future<void> saveEntry(LibraryEntry entry) async {
    await _database.saveEntry(entry);
    await _syncQuietly();
    notifyListeners();
  }

  Future<void> deleteEntry(String id) async {
    await _database.deleteEntry(id);
    await _syncQuietly();
    notifyListeners();
  }

  Future<void> saveLoan(BookLoan loan) async {
    await _database.saveLoan(loan);
    await reload();
    await _syncQuietly();
  }

  Future<void> signIn() async {
    await _authSync.signInWithGoogle();
    await reload();
  }

  Future<void> signOut() async {
    await _authSync.signOut();
    notifyListeners();
  }

  Future<void> syncNow() async {
    await _authSync.pull();
    await reload();
    await _authSync.push();
  }

  Future<void> _syncQuietly() async {
    try {
      await _authSync.push();
    } catch (_) {}
  }

  static String _tr(String value) => value.toLowerCase().replaceAll('ı', 'i');
  static int _bookYear(Book book) => book.firstPublishYear > 0 ? book.firstPublishYear : book.publicationYear;
}
