import 'dart:async';

import 'package:maxi_framework/maxi_framework.dart';

class Semaphore with DisposableMixin, InitializableMixin {
  late List<Completer<void>> _queue;

  bool _isBusy = false;

  bool get isBusy => _isBusy;

  bool get onlyHasOne => _isBusy && _queue.isEmpty;

  @override
  Result<void> performInitialization() {
    _queue = [];
    _isBusy = false;

    return voidResult;
  }

  Future<T> execute<T>(FutureOr<T> Function() function) async {
    initialize();
    await _checkIfBusy();

    try {
      _isBusy = true;
      return await function();
    } finally {
      if (_queue.isNotEmpty) {
        final next = _queue.removeAt(0);
        next.complete();
      } else {
        _isBusy = false;
      }
    }
  }

  Future<void> _checkIfBusy() async {
    await Future.delayed(Duration.zero);
    if (_isBusy) {
      final waiter = Completer();
      _queue.add(waiter);
      await waiter.future;
    }
  }

  Future<Result<T>> executeAsyncResult<T>(AsyncResult<T> executor) async {
    if (itWasDiscarded) {
      return CancelationResult(cancelationStackTrace: StackTrace.current);
    }

    final whenDispose = onDispose.whenComplete(() => executor.dispose());
    final result = await execute(() => executor.waitResult());

    whenDispose.ignore();
    return result;
  }

  Future<Result<T>> executeInteractivecResult<I, T>({required InteractiveResult<I, T> function, void Function(I)? onItem}) async {
    if (itWasDiscarded) {
      return CancelationResult(cancelationStackTrace: StackTrace.current);
    }

    final whenDispose = onDispose.whenComplete(() => function.dispose());
    final result = await execute(() => function.waitResult(onItem: onItem));

    whenDispose.ignore();
    return result;
  }

  @override
  void performObjectDiscard() {}
}
