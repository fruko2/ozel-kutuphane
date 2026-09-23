import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../core/constants/firebase_options.dart';
import '../../domain/models/book.dart';
import '../../domain/models/book_loan.dart';
import '../../domain/models/library_entry.dart';
import '../database/app_database.dart';

class AuthSyncService {
  AuthSyncService(this._database);
  final AppDatabase _database;
  FirebaseAuth? _auth;
  FirebaseFirestore? _firestore;
  String status = 'Yerel kütüphane hazır';

  User? get user => _auth?.currentUser;
  bool get isConfigured => _auth != null && _firestore != null;

  Future<void> initialize() async {
    try {
      await Firebase.initializeApp(options: FirebaseProjectOptions.android);
      _auth = FirebaseAuth.instance;
      _firestore = FirebaseFirestore.instance;
      _firestore!.settings = const Settings(persistenceEnabled: true);
      if (user != null) {
        status = '${user!.email ?? 'Google hesabı'} ile eşitleme açık';
        await pull();
      }
    } catch (_) {
      status = 'Çevrimdışı yerel kullanım';
    }
  }

  Future<void> signInWithGoogle() async {
    if (!isConfigured) throw Exception('Firebase başlatılamadı.');
    final account = await GoogleSignIn().signIn();
    if (account == null) return;
    final tokens = await account.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: tokens.accessToken,
      idToken: tokens.idToken,
    );
    await _auth!.signInWithCredential(credential);
    status = '${user?.email ?? 'Google hesabı'} ile eşitleme açık';
    await pull();
    await push();
  }

  Future<void> signOut() async {
    await GoogleSignIn().signOut();
    await _auth?.signOut();
    status = 'Yerel kütüphane hazır';
  }

  DocumentReference<Map<String, dynamic>>? get _document {
    final uid = user?.uid;
    if (uid == null || _firestore == null) return null;
    return _firestore!.collection('libraries').doc(uid);
  }

  Future<void> push() async {
    final document = _document;
    if (document == null) return;
    final books = await _database.allBooks();
    final entries = await _database.allEntries();
    final loans = await _database.allLoans();
    await document.set({
      'format': 'kutuphane-i-sahsi',
      'version': 1,
      'profile': {
        'name': user?.displayName ?? 'Okur',
        'email': user?.email ?? '',
        'bookGoal': 20,
        'pageGoal': 5000,
      },
      'books': books.map((item) => item.toCloudMap()).toList(),
      'entries': entries.map(_entryToCloud).toList(),
      'loans': loans.map(_loanToCloud).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> pull() async {
    final document = _document;
    if (document == null) return;
    final snapshot = await document.get();
    final data = snapshot.data();
    if (data == null) return;
    final cloudBooks = ((data['books'] as List<dynamic>?) ?? const [])
        .whereType<Map>()
        .map((value) => Book.fromCloudMap(Map<String, dynamic>.from(value)))
        .where((book) => book.id.isNotEmpty && book.title.isNotEmpty)
        .toList();
    final localBooks = await _database.allBooks();
    final merged = <String, Book>{for (final book in localBooks) book.id: book};
    for (final book in cloudBooks) {
      final local = merged[book.id];
      if (local == null || book.updatedAt.isAfter(local.updatedAt)) merged[book.id] = book;
    }
    await _database.saveBooks(merged.values);
    for (final raw in ((data['entries'] as List<dynamic>?) ?? const []).whereType<Map>()) {
      final map = Map<String, dynamic>.from(raw);
      final id = '${map['id'] ?? ''}', bookId = '${map['bookId'] ?? ''}';
      if (id.isEmpty || bookId.isEmpty) continue;
      await _database.saveEntry(LibraryEntry(
        id: id,
        bookId: bookId,
        kind: '${map['kind']}' == 'note' ? EntryKind.note : EntryKind.quote,
        pageNumber: _number(map['page'] ?? map['pageNumber']),
        content: '${map['content'] ?? ''}',
        createdAt: DateTime.tryParse('${map['createdAt'] ?? ''}') ?? DateTime.now(),
      ));
    }
    for (final raw in ((data['loans'] as List<dynamic>?) ?? const []).whereType<Map>()) {
      final map = Map<String, dynamic>.from(raw);
      final id = '${map['id'] ?? ''}', bookId = '${map['bookId'] ?? ''}';
      if (id.isEmpty || bookId.isEmpty) continue;
      await _database.saveLoan(BookLoan(
        id: id,
        bookId: bookId,
        borrowerName: '${map['borrowerName'] ?? ''}',
        borrowerContact: '${map['contact'] ?? map['borrowerContact'] ?? ''}',
        loanDate: _date(map['loanDate']) ?? DateTime.now(),
        expectedReturnDate: _date(map['expectedReturnDate']),
        returnedDate: _date(map['returnedDate']),
      ));
    }
  }

  static Map<String, Object?> _entryToCloud(LibraryEntry item) => {
        'id': item.id,
        'bookId': item.bookId,
        'kind': item.kind.name,
        'page': item.pageNumber,
        'content': item.content,
        'createdAt': item.createdAt.toUtc().toIso8601String(),
      };

  static Map<String, Object?> _loanToCloud(BookLoan item) => {
        'id': item.id,
        'bookId': item.bookId,
        'borrowerName': item.borrowerName,
        'contact': item.borrowerContact,
        'loanDate': item.loanDate.toUtc().toIso8601String(),
        'expectedReturnDate': item.expectedReturnDate?.toUtc().toIso8601String(),
        'returnedDate': item.returnedDate?.toUtc().toIso8601String(),
      };

  static int _number(Object? value) => value is num ? value.toInt() : int.tryParse('$value') ?? 0;
  static DateTime? _date(Object? value) => DateTime.tryParse('${value ?? ''}');
}

