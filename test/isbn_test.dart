import 'package:flutter_test/flutter_test.dart';
import 'package:kutuphane_i_sahsi/core/utils/isbn.dart';

void main() {
  test('geçerli ISBN-13 kabul edilir', () {
    expect(Isbn.isValid('978-975-07-1938-7'), isTrue);
  });

  test('hatalı kontrol basamağı reddedilir', () {
    expect(Isbn.isValid('9789750719388'), isFalse);
  });
}

