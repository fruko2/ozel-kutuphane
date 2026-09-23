enum ReadingStatus { wantToRead, reading, completed, unfinished }

extension ReadingStatusLabel on ReadingStatus {
  String get dbValue => switch (this) {
        ReadingStatus.wantToRead => 'want',
        ReadingStatus.reading => 'reading',
        ReadingStatus.completed => 'completed',
        ReadingStatus.unfinished => 'unfinished',
      };

  String get label => switch (this) {
        ReadingStatus.wantToRead => 'Okuyacağım',
        ReadingStatus.reading => 'Okuyorum',
        ReadingStatus.completed => 'Okudum',
        ReadingStatus.unfinished => 'Yarım bıraktım',
      };

  static ReadingStatus fromDb(String? value) => switch (value) {
        'reading' => ReadingStatus.reading,
        'completed' => ReadingStatus.completed,
        'unfinished' => ReadingStatus.unfinished,
        _ => ReadingStatus.wantToRead,
      };
}

