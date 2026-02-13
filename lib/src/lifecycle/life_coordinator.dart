import 'dart:async';

import 'package:maxi_framework/maxi_framework.dart';

class LifeCoordinator with DisposableMixin, LifecycleHub {
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
  
  
  

 
}
