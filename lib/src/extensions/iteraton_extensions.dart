extension IteratonExtensions<T> on Iterable<T> {
  T? selectItem(bool Function(T x) funcion) {
    for (final item in this) {
      if (funcion(item)) {
        return item;
      }
    }

    return null;
  }

  E? selectType<E>() {
    for (final item in this) {
      if (item is E) {
        return item;
      }
    }

    return null;
  }

  T maximumOf(num Function(T x) funcion) {
    return reduce((curr, next) => funcion(curr) > funcion(next) ? curr : next);
  }

  T minimumOf(num Function(T x) funcion) {
    return reduce((curr, next) => funcion(curr) < funcion(next) ? curr : next);
  }

  List<T> orderByFunction(dynamic Function(T) function) {
    final clon = toList();
    clon.sort((a, b) => function(a).compareTo(function(b)));
    return clon;
  }

  void lambda(Function(T x) function) {
    for (final item in this) {
      function(item);
    }
  }

  void lambdaWithPosition(Function(T item, int i) function) {
    int i = 0;
    for (final item in this) {
      function(item, i);
      i += 1;
    }
  }

  int selectPosition(bool Function(T) filtre) {
    int i = 0;
    for (final item in this) {
      if (filtre(item)) {
        return i;
      }
      i += 1;
    }

    return -1;
  }
}
