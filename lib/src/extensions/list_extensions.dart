extension ListExtensions<T> on List<T> {
  List<T> extractFrom(int from, [int? amount]) {
    if (isEmpty || from >= length) {
      return [];
    }

    final lista = <T>[];
    amount ??= length - from;
    int va = 0;

    for (int i = from; i < length; i++) {
      if (va >= amount) {
        break;
      }

      lista.add(this[i]);
      va = va + 1;
    }
    return lista;
  }

  List<T> addWhenMismatch(Iterable<T> otherList, bool Function(T,T) compare) {
    final newList = <T>[];

    for (final item in otherList) {
      if (!any((x) => compare(x, item))) {
        newList.add(item);
      }
    }

    addAll(newList);
    return newList;
  }
}
