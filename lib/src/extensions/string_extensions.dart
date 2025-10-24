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
}
