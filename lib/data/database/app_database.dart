import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../../domain/models/book.dart';
import '../../domain/models/book_loan.dart';
import '../../domain/models/library_entry.dart';

class AppDatabase {
  static const databaseVersion = 1;
  Database? _database;

  Future<Database> get instance async => _database ??= await _open();

  Future<Database> _open() async {
    final root = await getDatabasesPath();
    return openDatabase(
      join(root, 'kutuphane_i_sahsi.db'),
      version: databaseVersion,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE books (
            id TEXT PRIMARY KEY,
            isbn TEXT,
            title TEXT NOT NULL,
            subtitle TEXT NOT NULL DEFAULT '',
            author TEXT NOT NULL DEFAULT '',
            translator TEXT NOT NULL DEFAULT '',
            publisher TEXT NOT NULL DEFAULT '',
            category TEXT NOT NULL DEFAULT '',
            publication_year INTEGER NOT NULL DEFAULT 0,
            first_publish_year INTEGER NOT NULL DEFAULT 0,
            page_count INTEGER NOT NULL DEFAULT 0,
            current_page INTEGER NOT NULL DEFAULT 0,
            cover_url TEXT NOT NULL DEFAULT '',
            local_cover_path TEXT NOT NULL DEFAULT '',
            summary TEXT NOT NULL DEFAULT '',
            review TEXT NOT NULL DEFAULT '',
            rating INTEGER NOT NULL DEFAULT 0,
            reading_status TEXT NOT NULL DEFAULT 'want',
            series TEXT NOT NULL DEFAULT '',
            series_order INTEGER NOT NULL DEFAULT 0,
            previous_title TEXT NOT NULL DEFAULT '',
            series_sequential INTEGER NOT NULL DEFAULT 0,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');
        await db.execute(
          "CREATE UNIQUE INDEX idx_books_isbn ON books(isbn) WHERE isbn <> ''",
        );
        await db.execute('CREATE INDEX idx_books_author ON books(author)');
        await db.execute('CREATE INDEX idx_books_status ON books(reading_status)');
        await db.execute('''
          CREATE TABLE entries (
            id TEXT PRIMARY KEY,
            book_id TEXT NOT NULL REFERENCES books(id) ON DELETE CASCADE,
            kind TEXT NOT NULL,
            page_number INTEGER NOT NULL DEFAULT 0,
            content TEXT NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');
        await db.execute('CREATE INDEX idx_entries_book ON entries(book_id)');
        await db.execute('''
          CREATE TABLE loans (
            id TEXT PRIMARY KEY,
            book_id TEXT NOT NULL REFERENCES books(id) ON DELETE CASCADE,
            borrower_name TEXT NOT NULL,
            borrower_contact TEXT NOT NULL DEFAULT '',
            loan_date TEXT NOT NULL,
            expected_return_date TEXT,
            returned_date TEXT
          )
        ''');
        await db.execute('CREATE INDEX idx_loans_book ON loans(book_id)');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // Gelecekte her şema değişikliği burada eklemeli migration olarak yer alır.
      },
    );
  }

  Future<List<Book>> allBooks() async {
    final db = await instance;
    final rows = await db.query('books', orderBy: 'created_at DESC');
    return rows.map(Book.fromMap).toList(growable: false);
  }

  Future<Book?> bookByIsbn(String isbn, {String? excludingId}) async {
    if (isbn.isEmpty) return null;
    final db = await instance;
    final rows = await db.query(
      'books',
      where: excludingId == null ? 'isbn = ?' : 'isbn = ? AND id <> ?',
      whereArgs: excludingId == null ? [isbn] : [isbn, excludingId],
      limit: 1,
    );
    return rows.isEmpty ? null : Book.fromMap(rows.first);
  }

  Future<void> saveBook(Book book) async {
    final db = await instance;
    await db.insert('books', book.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> saveBooks(Iterable<Book> books) async {
    final db = await instance;
    await db.transaction((txn) async {
      for (final book in books) {
        await txn.insert('books', book.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  Future<void> deleteBook(String id) async {
    final db = await instance;
    await db.delete('books', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<LibraryEntry>> entriesFor(String bookId) async {
    final db = await instance;
    final rows = await db.query(
      'entries',
      where: 'book_id = ?',
      whereArgs: [bookId],
      orderBy: 'created_at DESC',
    );
    return rows.map(LibraryEntry.fromMap).toList(growable: false);
  }

  Future<List<LibraryEntry>> allEntries() async {
    final db = await instance;
    final rows = await db.query('entries', orderBy: 'created_at DESC');
    return rows.map(LibraryEntry.fromMap).toList(growable: false);
  }

  Future<void> saveEntry(LibraryEntry entry) async {
    final db = await instance;
    await db.insert('entries', entry.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteEntry(String id) async {
    final db = await instance;
    await db.delete('entries', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<BookLoan>> allLoans() async {
    final db = await instance;
    final rows = await db.query('loans', orderBy: 'loan_date DESC');
    return rows.map(BookLoan.fromMap).toList(growable: false);
  }

  Future<BookLoan?> activeLoanFor(String bookId) async {
    final db = await instance;
    final rows = await db.query(
      'loans',
      where: 'book_id = ? AND returned_date IS NULL',
      whereArgs: [bookId],
      orderBy: 'loan_date DESC',
      limit: 1,
    );
    return rows.isEmpty ? null : BookLoan.fromMap(rows.first);
  }

  Future<void> saveLoan(BookLoan loan) async {
    final db = await instance;
    await db.insert('loans', loan.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
