import 'dart:async';
import 'dart:developer';

import 'package:maxi_framework/maxi_framework.dart';
import 'package:meta/meta.dart';

final class LifecycleScope with DisposableMixin {
  final Disposable? _parent;

  List? _dynamicObjects;
  List<Function>? _disponsableFunctions;
  List<(dynamic, Function?, Future?)>? _disponsableManualObjects;
  List<(Disposable, Function?)>? _disponsableObjects;
  List<StreamController>? _unifiedStreamControlers;
  List<StreamSubscription>? _unifiedStreamSubscriptions;
  List<(Timer, Completer<bool>)>? _unifiedTimers;

  LifecycleScope() : _parent = null;

  LifecycleScope.withParent(Disposable parent) : _parent = parent {
    if (parent.itWasDiscarded) {
      throw NegativeResult.controller(
        code: ErrorCode.unacceptedState,
        message: const FixedOration(message: 'Parent object was discarded'),
      );
    }

    parent.onDispose.whenComplete(() {
      dispose();
    });
  }

  @override
  void performResurrection() {
    super.performResurrection();

    if (_parent != null) {
      if (_parent.itWasDiscarded) {
        if (_parent is DisposableMixin) {
          _parent.resurrectObject();
        } else {
          throw NegativeResult.controller(
            code: ErrorCode.implementationFailure,
            message: const FixedOration(message: 'Parent object was discarded and can not be used as a lifecycle scope parent'),
          );
        }
      }
      joinDisposableObject(_parent);
    }
  }

  @override
  @protected
  @mustCallSuper
  void performObjectDiscard() {
    if (_parent?.itWasDiscarded == false) {
      _parent?.dispose();
    }

    _disponsableObjects?.lambda((x) {
      x.$1.dispose();
      x.$2?.call();
    });
    _unifiedStreamControlers?.lambda((x) => x.close());
    _unifiedStreamSubscriptions?.lambda((x) => x.cancel());
    _unifiedTimers?.lambda((x) {
      x.$1.cancel();
      if (!x.$2.isCompleted) {
        x.$2.complete(false);
      }
    });
    _dynamicObjects?.lambda((x) {
      try {
        x.dispose();
      } catch (ex) {
        log('Object $runtimeType has no dispose function or failed($ex)');
      }
    });

    _disponsableFunctions?.lambda((x) {
      volatileFunction(
        error: (ex, st) => ExceptionResult(
          exception: ex,
          stackTrace: st,
          message: const FixedOration(message: 'An internal error occurred while executing a feature'),
        ),
        function: () => x(),
      ).logIfFails();
    });

    _disponsableManualObjects?.lambda((x) {
      volatileFunction(
        error: (ex, st) => ExceptionResult(
          exception: ex,
          stackTrace: st,
          message: const FixedOration(message: 'An internal error occurred while executing a feature'),
        ),
        function: () {
          if (x.$2 != null) {
            x.$2!(x.$1);
          }
        },
      ).logIfFails();
      x.$3?.ignore();
      if (x.$1 is Disposable) {
        (x.$1 as Disposable).dispose();
      }
    });

    _dynamicObjects?.clear();
    _disponsableObjects?.clear();
    _unifiedStreamControlers?.clear();
    _unifiedStreamSubscriptions?.clear();
    _unifiedTimers?.clear();
    _disponsableFunctions?.clear();
    _disponsableManualObjects?.clear();
    _dynamicObjects = null;
    _disponsableObjects = null;
    _unifiedStreamControlers = null;
    _unifiedStreamSubscriptions = null;
    _unifiedTimers = null;
    _disponsableFunctions = null;
    _disponsableManualObjects = null;
  }

  T joinDynamicObject<T>(T item) {
    if (itWasDiscarded) {
      try {
        (item as dynamic).dispose();
      } catch (ex) {
        log('Object $runtimeType has no dispose function or failed($ex)');
      }

      return item;
    }

    resurrectObject();
    _dynamicObjects ??= [];
    _dynamicObjects!.add(item);
    return item;
  }

  T joinDisposableObject<T extends Disposable>(T item, [Function? onDisposeFunction]) {
    if (itWasDiscarded) {
      item.dispose();
      return item;
    }

    resurrectObject();
    _disponsableObjects ??= <(Disposable, Function?)>[];
    final func = (item, onDisposeFunction);
    _disponsableObjects!.add(func);

    item.onDispose.whenComplete(() {
      if (!itWasDiscarded) {
        _disponsableObjects!.remove(func);
      }
    });

    return item;
  }

  void doneFunction(Function funtion) {
    resurrectObject();
    _disponsableFunctions ??= <Function>[];
    _disponsableFunctions!.add(funtion);
  }

  Result<void> createDependency(Disposable item) {
    if (item.itWasDiscarded) {
      return NegativeResult.controller(
        code: ErrorCode.discontinuedFunctionality,
        message: const FixedOration(message: 'The dependency item was already discarded'),
      );
    }
    resurrectObject();
    final link = item.onDispose.whenComplete(dispose);
    onDispose.whenComplete(() => link.ignore());
    return voidResult;
  }

  StreamController<T> joinStreamController<T>(StreamController<T> controller) {
    if (itWasDiscarded) {
      controller.close();
      return controller;
    }

    resurrectObject();
    _unifiedStreamControlers ??= <StreamController>[];
    _unifiedStreamControlers!.add(controller);

    controller.done.whenComplete(() {
      if (!itWasDiscarded) {
        _unifiedStreamControlers!.remove(controller);
      }
    });

    return controller;
  }

  StreamSubscription<T> joinStream<T>({required Stream<T> stream, required void Function(T event) onData, Function? onError, void Function()? onDone, bool? cancelOnError}) {
    late final StreamSubscription<T> subscription;
    subscription = stream.listen(
      onData,
      onError: onError,
      cancelOnError: cancelOnError,
      onDone: () {
        if (onDone != null) {
          onDone();
        }
        _unifiedStreamSubscriptions?.remove(subscription);
      },
    );
    joinStreamSubscription<T>(subscription);
    return subscription;
  }

  StreamSubscription<T> joinStreamSubscription<T>(StreamSubscription<T> subscription) {
    if (itWasDiscarded) {
      subscription.cancel();
      return subscription;
    }

    resurrectObject();
    _unifiedStreamSubscriptions ??= <StreamSubscription>[];
    _unifiedStreamSubscriptions!.add(subscription);
    return subscription;
  }

  T joinManualDisposableObject<T>(T object, {Function(T)? onDisponse, Future? ignorantFuturo}) {
    if (itWasDiscarded) {
      onDisponse?.call(object);
      return object;
    }

    resurrectObject();
    _disponsableManualObjects ??= <(dynamic, Function?, Future?)>[];

    final func = (object, onDisponse, ignorantFuturo);
    if (ignorantFuturo != null) {
      ignorantFuturo.whenComplete(() => _disponsableManualObjects!.remove(func));
    }

    _disponsableManualObjects!.add(func);
    return object;
  }

  FutureResult<T> waitCompleter<T>(Completer<T> completer) async {
    if (itWasDiscarded) {
      final cancel = CancelationResult<T>();
      appManager.exceptionChannel.sendItem((cancel, StackTrace.current));
      if (!completer.isCompleted) {
        completer.completeError(cancel, StackTrace.current);
      }
      return cancel;
    }

    resurrectObject();

    final onDisponseBefore = onDispose.whenComplete(() {
      final cancel = CancelationResult<T>();
      if (!completer.isCompleted) {
        completer.completeError(cancel, StackTrace.current);
      }
      appManager.exceptionChannel.sendItem((cancel, StackTrace.current));
    });

    final futureResult = await completer.future.toFutureResult();
    onDisponseBefore.ignore();

    return futureResult;
  }

  Future<Result<T>> waitFuture<T>({required Future<T> Function() function}) async {
    if (itWasDiscarded) {
      final cancel = CancelationResult<T>();
      appManager.exceptionChannel.sendItem((cancel, StackTrace.current));
      return cancel;
    }

    resurrectObject();
    final completer = Completer<Result<T>>();

    final executor = function()
        .then((x) => completer.complete(ResultValue(content: x)))
        .onError(
          (ex, st) => ExceptionResult(
            exception: ex,
            stackTrace: st,
            message: FixedOration(message: 'An internal error occurred while executing a feature'),
          ),
        );
    final done = onDispose.whenComplete(() {
      executor.ignore();
      final cancel = CancelationResult<T>();
      if (!completer.isCompleted) {
        completer.complete(cancel);
      }
      appManager.exceptionChannel.sendItem((cancel, StackTrace.current));
    });

    final futureResult = await completer.future;
    done.ignore();
    executor.ignore();

    return futureResult;
  }

  Future<Result<T>> waitFutureResult<T>({required Future<Result<T>> Function() function}) async {
    if (itWasDiscarded) {
      final cancel = CancelationResult<T>();
      appManager.exceptionChannel.sendItem((cancel, StackTrace.current));
      return cancel;
    }

    resurrectObject();
    final completer = Completer<Result<T>>();

    final executor = function()
        .then((x) => completer.complete(x))
        .onError(
          (ex, st) => ExceptionResult(
            exception: ex,
            stackTrace: st,
            message: FixedOration(message: 'An internal error occurred while executing a feature'),
          ),
        );
    final done = onDispose.whenComplete(() {
      executor.ignore();
      final cancel = CancelationResult<T>();
      if (!completer.isCompleted) {
        completer.complete(cancel);
      }
      appManager.exceptionChannel.sendItem((cancel, StackTrace.current));
    });

    final futureResult = await completer.future;
    done.ignore();
    executor.ignore();

    return futureResult;
  }

  Future<bool> delay({required Duration duration}) async {
    if (itWasDiscarded) {
      return false;
    }

    resurrectObject();

    late final (Timer, Completer<bool>) instance;

    final completer = Completer<bool>();
    final timer = Timer(duration, () {
      _unifiedTimers?.remove(instance);
      if (!completer.isCompleted) {
        completer.complete(true);
      }
    });

    instance = (timer, completer);
    _unifiedTimers ??= <(Timer, Completer<bool>)>[];
    _unifiedTimers!.add(instance);

    return completer.future;
  }

  Future<Result<T>> waitAsyncResult<T>(AsyncResult<T> asyncResult) async {
    if (itWasDiscarded) {
      final cancel = CancelationResult<T>();
      appManager.exceptionChannel.sendItem((cancel, StackTrace.current));
      return cancel;
    }

    resurrectObject();

    joinDisposableObject(asyncResult);
    return asyncResult.waitResult();
  }
}
