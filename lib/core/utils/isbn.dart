abstract final class Isbn {
  static String normalize(String value) =>
      value.replaceAll(RegExp(r'[^0-9Xx]'), '').toUpperCase();

  static bool isValid(String input) {
    final value = normalize(input);
    if (RegExp(r'^97[89][0-9]{10}$').hasMatch(value)) {
      var sum = 0;
      for (var i = 0; i < value.length; i++) {
        sum += int.parse(value[i]) * (i.isOdd ? 3 : 1);
      }
      return sum % 10 == 0;
    }
    if (RegExp(r'^[0-9]{9}[0-9X]$').hasMatch(value)) {
      var sum = 0;
      for (var i = 0; i < value.length; i++) {
        sum += (value[i] == 'X' ? 10 : int.parse(value[i])) * (10 - i);
      }
      return sum % 11 == 0;
    }
    return false;
  }
}

