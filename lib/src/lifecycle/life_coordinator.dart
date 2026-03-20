import 'dart:async';

import 'package:maxi_framework/maxi_framework.dart';

FutureResult<T> usingHeart<T>(FutureResult<T> Function(LifeCoordinator heart) function) async {
  if (LifeCoordinator.isZoneHeartCanceled) {
    final cancel = CancelationResult<T>();
    appManager.exceptionChannel.sendItem((cancel, StackTrace.current));
    return cancel;
  }

  final newHeart = AsyncExecutor(function: () => function(LifeCoordinator.zoneHeart), connectToZone: true);
  final result = await newHeart.waitResult();
  newHeart.dispose();
  return result;
}

class LifeCoordinator with DisposableMixin, LifecycleHub {
  StackTrace? _creationStackTrace;
  StackTrace? _disponseStackTrace;

  StackTrace get creationStackTrace {
    return _creationStackTrace ?? StackTrace.empty;
  }

  StackTrace get disponseStackTrace {
    return _disponseStackTrace ?? StackTrace.empty;
  }

  static FutureResult<T> runWithSeparateZone<T>(FutureResult<T> Function() function)  {
    final completer = Completer<Result<T>>();
    final newExecutor = AsyncExecutor(function: function, connectToZone: false);
    scheduleMicrotask(() async {
      final result = await newExecutor.waitResult();
      completer.complete(result);
    });
    return completer.future;
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
}
