extension StringExtensions on String {
  String get first {
    if (isEmpty) {
      return '';
    } else {
      return this[0];
    }
  }

  String get last {
    if (isEmpty) {
      return '';
    } else {
      return this[length - 1];
    }
  }

  String extractFrom({int since = 0, int? amount}) {
    final buffer = StringBuffer();
    if (amount == null || amount >= length) {
      for (int i = since; i < length; i++) {
        buffer.write(this[i]);
      }
    } else {
      for (int i = since; i < since + amount && i < length; i++) {
        buffer.write(this[i]);
      }
    }

    return buffer.toString();
  }

  String extractInverselyFrom({int? since, int? amount}) {
    final buffer = <String>[];
    since ??= isNotEmpty ? length - 1 : 0;

    if (since >= length) {
      since = length - 1;
    }

    if (amount == null || amount >= length) {
      for (int i = since; i >= 0; i--) {
        buffer.add(this[i]);
      }
    } else {
      for (int i = since; i >= 0 && buffer.length < amount; i--) {
        buffer.add(this[i]);
      }
    }

    return buffer.reversed.join();
  }

  String removeLastCharacters(int amount) {
    final buffer = StringBuffer();

    for (int i = length - 1 - amount; i >= 0; i--) {
      buffer.write(this[i]);
    }
    return buffer.toString();
  }

  String firstWithLowercase() {
    if (isEmpty) return this;
    return '${this[0].toLowerCase()}${extractFrom(since: 1)}';
  }

  String firstWithUppercase() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${extractFrom(since: 1)}';
  }

  String zeroFill({required int quantityZeros, bool cutIfExceeds = true, bool cutFromTheEnd = true}) {
    if (length > quantityZeros) {
      if (cutIfExceeds) {
        if (cutFromTheEnd) {
          return extractFrom(since: length - quantityZeros);
        } else {
          return extractFrom(since: 0, amount: quantityZeros);
        }
      } else {
        return this;
      }
    }

    final buffer = StringBuffer();
    for (int i = length; i < quantityZeros; i++) {
      buffer.write('0');
    }

    buffer.write(this);
    return buffer.toString();
  }

  String clearLatin1() {
    final buffer = StringBuffer();
    for (var rune in runes) {
      if (rune <= 0xFF) {
        buffer.writeCharCode(rune);
      }
    }
    return buffer.toString();
  }
}
