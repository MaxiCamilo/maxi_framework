import 'dart:async';
import 'dart:developer';

import 'package:maxi_framework/maxi_framework.dart';

class ParentController with DisposableMixin, InitializableMixin {
  late List _dynamicObjects;
  late List<Disposable> _disponsableObjects;
  late List<StreamController> _unifiedStreamControlers;
  late List<StreamSubscription> _unifiedStreamSubscriptions;
  late List<(Timer, Completer<bool>)> _unifiedTimers;

  T joinDynamicObject<T>(T item) {
    if (itWasDiscarded) {
      try {
        (item as dynamic).dispose();
      } catch (ex) {
        log('Object $runtimeType has no dispose function or failed($ex)');
      }

      return item;
    }

    initialize();
    _dynamicObjects.add(item);
    return item;
  }

  T joinDisposableObject<T extends Disposable>(T item) {
    if (itWasDiscarded) {
      item.dispose();
      return item;
    }

    initialize();
    _disponsableObjects.add(item);

    item.onDispose.whenComplete(() {
      if (!itWasDiscarded) {
        _disponsableObjects.remove(item);
      }
    });

    return item;
  }

  StreamController<T> joinStreamController<T>(StreamController<T> controller) {
    if (itWasDiscarded) {
      controller.close();
      return controller;
    }

    initialize();
    _unifiedStreamControlers.add(controller);

    controller.done.whenComplete(() {
      if (!itWasDiscarded) {
        _unifiedStreamControlers.remove(controller);
      }
    });

    return controller;
  }

  StreamSubscription<T> joinStreamSubscription<T>(StreamSubscription<T> subscription) {
    if (itWasDiscarded) {
      subscription.cancel();
      return subscription;
    }

    initialize();
    _unifiedStreamSubscriptions.add(subscription);
    return subscription;
  }

  Future<Result<T>> waitFuture<T>({required Future<T> Function() function}) async {
    if (itWasDiscarded) {
      return CancelationResult(cancelationStackTrace: StackTrace.current);
    }

    initialize();
    final completer = Completer<Result<T>>();

    final executor = function().then((x) => completer.complete(PositiveResult(content: x))).onError((ex, st) => ExceptionResult(exception: ex, stackTrace: st));
    final done = onDispose.whenComplete(() {
      executor.ignore();
      completer.complete(CancelationResult(cancelationStackTrace: StackTrace.current));
    });

    final futureResult = await completer.future;
    done.ignore();
    executor.ignore();

    return futureResult;
  }

  Future<Result<T>> waitFutureResult<T>({required Future<Result<T>> Function() function}) async {
    if (itWasDiscarded) {
      return CancelationResult(cancelationStackTrace: StackTrace.current);
    }

    initialize();
    final completer = Completer<Result<T>>();

    final executor = function().then((x) => completer.complete(x)).onError((ex, st) => ExceptionResult(exception: ex, stackTrace: st));
    final done = onDispose.whenComplete(() {
      executor.ignore();
      if (!completer.isCompleted) {
        completer.complete(CancelationResult(cancelationStackTrace: StackTrace.current));
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

    initialize();

    late final (Timer, Completer<bool>) instance;

    final completer = Completer<bool>();
    final timer = Timer(duration, () {
      _unifiedTimers.remove(instance);
      if (!completer.isCompleted) {
        completer.complete(true);
      }
    });

    instance = (timer, completer);
    _unifiedTimers.add(instance);

    return completer.future;
  }

  @override
  Result<void> performInitialization() {
    _dynamicObjects = [];
    _disponsableObjects = <Disposable>[];
    _unifiedStreamControlers = <StreamController>[];
    _unifiedStreamSubscriptions = <StreamSubscription>[];
    _unifiedTimers = <(Timer, Completer<bool>)>[];

    return positiveVoidResult;
  }

  @override
  void performObjectDiscard() {
    if (!isInitialized) {
      return;
    }

    _disponsableObjects.lambda((x) => x.dispose());
    _unifiedStreamControlers.lambda((x) => x.close());
    _unifiedStreamSubscriptions.lambda((x) => x.cancel());
    _unifiedTimers.lambda((x) {
      x.$1.cancel();
      if (!x.$2.isCompleted) {
        x.$2.complete(false);
      }
    });
    _dynamicObjects.lambda((x) {
      try {
        x.dispose();
      } catch (ex) {
        log('Object $runtimeType has no dispose function or failed($ex)');
      }
    });

    _dynamicObjects.clear();
    _disponsableObjects.clear();
    _unifiedStreamControlers.clear();
    _unifiedStreamSubscriptions.clear();
    _unifiedTimers.clear();
  }
}
