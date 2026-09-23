class BookLoan {
  const BookLoan({
    required this.id,
    required this.bookId,
    required this.borrowerName,
    required this.loanDate,
    this.borrowerContact = '',
    this.expectedReturnDate,
    this.returnedDate,
  });

  final String id;
  final String bookId;
  final String borrowerName;
  final String borrowerContact;
  final DateTime loanDate;
  final DateTime? expectedReturnDate;
  final DateTime? returnedDate;

  bool get isReturned => returnedDate != null;

  Map<String, Object?> toMap() => {
        'id': id,
        'book_id': bookId,
        'borrower_name': borrowerName,
        'borrower_contact': borrowerContact,
        'loan_date': loanDate.toUtc().toIso8601String(),
        'expected_return_date': expectedReturnDate?.toUtc().toIso8601String(),
        'returned_date': returnedDate?.toUtc().toIso8601String(),
      };

  factory BookLoan.fromMap(Map<String, Object?> map) => BookLoan(
        id: map['id'] as String,
        bookId: map['book_id'] as String,
        borrowerName: map['borrower_name'] as String? ?? '',
        borrowerContact: map['borrower_contact'] as String? ?? '',
        loanDate: DateTime.tryParse(map['loan_date'] as String? ?? '') ?? DateTime.now(),
        expectedReturnDate: DateTime.tryParse(map['expected_return_date'] as String? ?? ''),
        returnedDate: DateTime.tryParse(map['returned_date'] as String? ?? ''),
      );
}

