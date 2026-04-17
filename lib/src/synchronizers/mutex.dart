import 'dart:async';

import 'package:maxi_framework/maxi_framework.dart';

class Mutex with DisposableMixin, InitializableMixin {
  late List<Completer<bool>> _queue;

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
    final itsActive = await _checkIfBusy();
    if (itsActive.itsFailure) {
      throw itsActive.error;
    }

    try {
      _isBusy = true;
      return await function();
    } finally {
      if (_queue.isNotEmpty) {
        final next = _queue.removeAt(0);
        next.complete(true);
      } else {
        _isBusy = false;
        _awaitAllQueued?.complete(true);
        _awaitAllQueued = null;
      }
    }
  }

  FutureResult<T> executeResult<T>(FutureOr<Result<T>> Function() function, {Oration? exceptionMessage}) async {
    initialize();
    final itsActive = await _checkIfBusy();
    if (itsActive.itsFailure) {
      return itsActive.cast();
    }

    try {
      _isBusy = true;
      return await function();
    } catch (ex, st) {
      return ExceptionResult(
        exception: ex,
        stackTrace: st,
        message: exceptionMessage ?? const FixedOration(message: 'An exception was thrown during the execution of a Mutex-protected function'),
      );
    } finally {
      if (_queue.isNotEmpty) {
        final next = _queue.removeAt(0);
        next.complete(true);
      } else {
        _isBusy = false;
        _awaitAllQueued?.complete(true);
        _awaitAllQueued = null;
      }
    }
  }

  FutureResult<void> _checkIfBusy() async {
    await Future.delayed(Duration.zero);

    if (_isBusy) {
      final waiter = Completer<bool>();
      _queue.add(waiter);

      TinyEvent? onDisposeHeart;
      final currentHeart = LifeCoordinator.tryGetZoneHeart;
      if (currentHeart != null && !currentHeart.itWasDiscarded) {
        onDisposeHeart = currentHeart.onDispose.whenComplete(() {
          _queue.remove(waiter);

          waiter.complete(false);
        });
      }

      final isValid = await waiter.future;
      onDisposeHeart?.ignore();
      if (!isValid) {
        return CancelationResult();
      }
    }
    return voidResult;
  }

  Future<Result<T>> executeAsyncResult<T>(AsyncResult<T> executor) async {
    if (itWasDiscarded) {
      final cancel = CancelationResult<T>();
      appManager.exceptionChannel.sendItem((cancel, StackTrace.current));
      return cancel;
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
