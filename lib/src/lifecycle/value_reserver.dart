import 'dart:async';

import 'package:maxi_framework/maxi_framework.dart';

abstract interface class ValueReserver<T> implements Disposable {
  FutureResult<R> invoke<R>({required FutureOr<Result<R>> Function(T) function, Duration? timeout});

  factory ValueReserver.resultValue(Result<T> result) => _ValueReserver(() => result);
  factory ValueReserver.futureResult(FutureResult<T> futureResult) => _ValueReserver(() => futureResult);

  factory ValueReserver.value(T value) {
    final reserver = _ValueReserver(() => ResultValue(content: value));
    if (value is Disposable) {
      value.onDispose.whenComplete(() => reserver.dispose());
    }
    return reserver;
  }
}

class _ValueReserver<T> with DisposableMixin implements ValueReserver<T> {
  final FutureOr<Result<T>> Function() _valueGetter;
  final Mutex _mutex = Mutex();

  _ValueReserver(this._valueGetter);

  @override
  FutureResult<R> invoke<R>({required FutureOr<Result<R>> Function(T) function, Duration? timeout}) async {
    Future<Result<R>> future = _mutex.executeResult(() async {
      final valueResult = await _valueGetter();
      if (valueResult.itsFailure) {
        return valueResult.cast();
      }

      return await function(valueResult.content);
    });
    if (timeout != null) {
      future = future.setTimeoutError(
        timeout: timeout,
        message: const FixedOration(message: 'The reservation has timed out'),
      );
    }

    return await future;
  }

  @override
  void performObjectDiscard() {
    _mutex.dispose();
  }
}
