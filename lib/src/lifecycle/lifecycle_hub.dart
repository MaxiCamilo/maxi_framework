import 'dart:async';
import 'dart:developer';

import 'package:maxi_framework/maxi_framework.dart';
import 'package:meta/meta.dart';

mixin LifecycleHub on DisposableMixin {
  List? _dynamicObjects;
  List<Function>? _disponsableFunctions;
  List<Disposable>? _disponsableObjects;
  List<StreamController>? _unifiedStreamControlers;
  List<StreamSubscription>? _unifiedStreamSubscriptions;
  List<(Timer, Completer<bool>)>? _unifiedTimers;

  @protected
  @override
  @mustCallSuper
  void performResurrection() {
    super.performResurrection();
  }

  @protected
  @override
  @mustCallSuper
  void performObjectDiscard() {
    _disponsableObjects?.lambda((x) => x.dispose());
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

    _dynamicObjects?.clear();
    _disponsableObjects?.clear();
    _unifiedStreamControlers?.clear();
    _unifiedStreamSubscriptions?.clear();
    _unifiedTimers?.clear();
    _disponsableFunctions?.clear();

    _dynamicObjects = null;
    _disponsableObjects = null;
    _unifiedStreamControlers = null;
    _unifiedStreamSubscriptions = null;
    _unifiedTimers = null;
    _disponsableFunctions = null;
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

  T joinDisposableObject<T extends Disposable>(T item) {
    if (itWasDiscarded) {
      item.dispose();
      return item;
    }

    resurrectObject();
    _disponsableObjects ??= <Disposable>[];
    _disponsableObjects!.add(item);

    item.onDispose.whenComplete(() {
      if (!itWasDiscarded) {
        _disponsableObjects!.remove(item);
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
    item.onDispose.whenComplete(dispose);
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

  Future<Result<T>> waitFuture<T>({required Future<T> Function() function}) async {
    if (itWasDiscarded) {
      return CancelationResult();
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
      completer.complete(CancelationResult());
    });

    final futureResult = await completer.future;
    done.ignore();
    executor.ignore();

    return futureResult;
  }

  Future<Result<T>> waitFutureResult<T>({required Future<Result<T>> Function() function}) async {
    if (itWasDiscarded) {
      return CancelationResult();
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
      if (!completer.isCompleted) {
        completer.complete(CancelationResult());
      }
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
      return CancelationResult<T>();
    }

    resurrectObject();

    joinDisposableObject(asyncResult);
    return asyncResult.waitResult();
  }
}
