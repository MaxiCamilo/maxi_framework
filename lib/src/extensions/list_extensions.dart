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
}
