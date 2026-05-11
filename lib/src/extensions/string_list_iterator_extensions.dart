extension StringListExtensions on Iterable<String> {
  Iterable<String> addToStart(String toAdd) sync* {
    for (final item in this) {
      yield '$toAdd$item';
    }
  }

  Iterable<String> omitEmptyItems() sync* {
    for (final item in this) {
      if (item.isNotEmpty) {
        yield item;
      }
    }
  }
}
