import 'package:maxi_framework/maxi_framework.dart';

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

  Result<List<R>> volatileMap<R>(R Function(T) transform, {Oration Function(T, Object)? buildMessage}) {
    final newList = <R>[];
    for (final element in this) {
      try {
        newList.add(transform(element));
      } catch (ex, st) {
        appManager.exceptionChannel.sendItem((ex, st));
        late final Oration message;
        if (buildMessage == null) {
          message = const FixedOration(message: 'An error occurred while processing a list element');
        } else {
          message = buildMessage(element, ex);
        }

        return ExceptionResult(exception: ex, stackTrace: st, message: message);
      }
    }

    return newList.asResultValue();
  }

  Result<List<R>> resultMap<R>(Result<R> Function(T) transform, {NegativeResult<List<R>> Function(T, Object)? onError}) {
    final newList = <R>[];
    for (final element in this) {
      final result = transform(element);
      if (result.itsFailure) {
        return result.cast();
      }

      newList.add(result.content);
    }

    return newList.asResultValue();
  }
}
