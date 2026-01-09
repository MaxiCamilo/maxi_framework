import 'dart:async';
import 'dart:developer';

import 'package:maxi_framework/maxi_framework.dart';

class LifeCoordinator with DisposableMixin, InitializableMixin {
  late List _dynamicObjects;
  late List<Disposable> _disponsableObjects;
  late List<StreamController> _unifiedStreamControlers;
  late List<StreamSubscription> _unifiedStreamSubscriptions;
  late List<(Timer, Completer<bool>)> _unifiedTimers;

  StackTrace? _creationStackTrace;
  StackTrace? _disponseStackTrace;

  StackTrace get creationStackTrace {
    return _creationStackTrace ?? StackTrace.empty;
  }

  StackTrace get disponseStackTrace {
    return _disponseStackTrace ?? StackTrace.empty;
  }

  //LOCAL ZONE MANAGER

  static const kZoneHeart = #maxiZoneHeart;
  static bool get hasZoneHeart => Zone.current[kZoneHeart] != null;
  static bool get isZoneHeartCanceled => Zone.current[kZoneHeart] != null && (Zone.current[kZoneHeart] as Disposable).itWasDiscarded;

  static LifeCoordinator get zoneHeart {
    final item = Zone.current[kZoneHeart];
    if (item == null) {
      throw NegativeResult(
        error: ControlledFailure(
          errorCode: ErrorCode.implementationFailure,
          message: FixedOration(message: 'An object handler was not defined in this zone'),
        ),
      );
    }

    return item as LifeCoordinator;
  }

  static LifeCoordinator? get tryGetZoneHeart {
    final item = Zone.current[kZoneHeart];
    if (item == null) {
      return null;
    }

    return item as LifeCoordinator;
  }

  //////

  /////ROOT ZONE MANAGER

  static const kRootZoneHeart = #kRootZoneHeart;
  static bool get hasRootZoneHeart => Zone.current[kRootZoneHeart] != null;

  static LifeCoordinator get rootZoneHeart {
    final item = Zone.current[kRootZoneHeart];
    if (item == null) {
      throw NegativeResult(
        error: ControlledFailure(
          errorCode: ErrorCode.implementationFailure,
          message: FixedOration(message: 'An object handler was not defined in root zone'),
        ),
      );
    }

    return item as LifeCoordinator;
  }

  //////

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

  StreamSubscription<T> joinStream<T>({required Stream<T> stream, required void Function(T event) onData,  Function? onError, void Function()? onDone, bool? cancelOnError}) {
    late final StreamSubscription<T> subscription;
    subscription = stream.listen(
      onData,
      onError: onError,
      cancelOnError: cancelOnError,
      onDone: () {
        if (onDone != null) {
          onDone();
        }
        _unifiedStreamSubscriptions.remove(subscription);
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

    initialize();
    _unifiedStreamSubscriptions.add(subscription);
    return subscription;
  }

  Future<Result<T>> waitFuture<T>({required Future<T> Function() function}) async {
    if (itWasDiscarded) {
      return CancelationResult();
    }

    initialize();
    final completer = Completer<Result<T>>();

    final executor = function().then((x) => completer.complete(ResultValue(content: x))).onError((ex, st) => ExceptionResult(exception: ex, stackTrace: st));
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

    initialize();
    final completer = Completer<Result<T>>();

    final executor = function().then((x) => completer.complete(x)).onError((ex, st) => ExceptionResult(exception: ex, stackTrace: st));
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

  Future<Result<T>> waitAsyncResult<T>(AsyncResult<T> asyncResult) async {
    if (itWasDiscarded) {
      return CancelationResult<T>();
    }

    initialize();

    final whenDispose = onDispose.whenComplete(asyncResult.dispose);

    final result = asyncResult.waitResult();

    whenDispose.ignore();
    return result;
  }

  bool connectWithHeartZone() {
    final heartZone = tryGetZoneHeart;
    if (heartZone == null) return false;

    heartZone.joinDisposableObject(this);
    return true;
  }

  @override
  Result<void> performInitialization() {
    _dynamicObjects = [];
    _disponsableObjects = <Disposable>[];
    _unifiedStreamControlers = <StreamController>[];
    _unifiedStreamSubscriptions = <StreamSubscription>[];
    _unifiedTimers = <(Timer, Completer<bool>)>[];

    _creationStackTrace = StackTrace.current;

    return voidResult;
  }

  @override
  void performObjectDiscard() {
    _disponseStackTrace = StackTrace.current;
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
