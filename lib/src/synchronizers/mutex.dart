import 'dart:async';

import 'package:maxi_framework/maxi_framework.dart';

class Mutex with DisposableMixin, InitializableMixin {
  late List<Completer<void>> _queue;

  Completer? _awaitAllQueued;

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
        _awaitAllQueued?.complete(null);
        _awaitAllQueued = null;
      }
    }
  }

  Future<T> executeInteractive<I, T>({required FutureOr<T> Function() function, required void Function(I) onItem}) {
    return execute(() => InteractiveSystem.catchItems<I, T>(function: function, onItem: onItem));
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
      return CancelationResult();
    }

    final whenDispose = onDispose.whenComplete(() => executor.dispose());
    final result = await execute(() => executor.waitResult());

    whenDispose.ignore();
    return result;
  }

  Future<Result<T>> executeInZone<T>(FutureOr<T> Function() function) {
    initialize();
    final completer = Completer<Result<T>>();

    execute(() async {
      if (completer.isCompleted) return;

      final executor = AsyncExecutor.function(function: function);
      final onDispose = bindChild(executor);

      final result = await executor.waitResult();
      onDispose.ignore();
      if (!completer.isCompleted) {
        completer.complete(result);
      }
    });

    return completer.future;
  }

  Future<T> executeWhenNotBusy<T>(FutureOr<T> Function() function) async {
    if (!isBusy) {
      return execute(function);
    }

    _awaitAllQueued ??= Completer();
    await _awaitAllQueued!.future;

    return execute(function);
  }

  @override
  void performObjectDiscard() {
    _queue.lambda((waiter) => waiter.completeError(CancelationResult()));
    _queue.clear();

    _awaitAllQueued?.completeError(CancelationResult());
    _awaitAllQueued = null;
  }
}
