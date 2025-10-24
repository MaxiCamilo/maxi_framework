import 'dart:async';
import 'dart:developer';

import 'package:maxi_framework/maxi_framework.dart';

Future<Result<T>> managedFunction<T>(FutureOr<Result<T>> Function(LifeCoordinator heart) function) async {
  final heart = LifeCoordinator.tryGetZoneHeart;

  if (heart == null) {
    final newOperator = AsyncExecutor<T>(function: () => function(LifeCoordinator.zoneHeart));
    return newOperator.waitResult();
  } else {
    return function(heart);
  }
}

Result<T> volatileFunction<T>({required Result<T> Function(dynamic ex, StackTrace st) error, required T Function() function}) {
  try {
    return ResultValue(content: function());
  } catch (ex, st) {
    return error(ex, st);
  }
}

Future<Result<T>> volatileFuture<T>({required Result<T> Function(dynamic ex, StackTrace st) error, required FutureOr<T> Function() function, FutureOr<void> Function()? onDone, FutureOr<void> Function()? onError}) async {
  bool onDoneCalled = false;
  final heart = LifeCoordinator.tryGetZoneHeart;

  if (heart == null) {
    return managedFunction<T>((heart) => volatileFuture(error: error, function: function, onDone: onDone, onError: onError));
  }

  try {
    if (heart.itWasDiscarded) {
      if (onDone != null) {
        onDoneCalled = true;
        await onDone();
      }
      return const  CancelationResult();
    }

    final result = ResultValue<T>(content: await function());
    if (onDone != null) {
      onDoneCalled = true;
      await onDone();
    }

    if (heart.itWasDiscarded) {
      return const  CancelationResult();
    }

    return result;
  } catch (ex, st) {
    if (onDone != null && !onDoneCalled) {
      try {
        await onDone();
      } catch (ex, st) {
        log('[VolatileFuture] Error in onDone! $ex');
        return error(ex, st);
      }
    }

    if (onError != null) {
      try {
        await onError();
      } catch (ex, st) {
        log('[VolatileFuture] Error in onError! $ex');
        return error(ex, st);
      }
    }
    return error(ex, st);
  }
}

extension FutureResultExtensions<T> on Future<Result<T>> {
  Future<Result<T>> connect() async {
    final heart = LifeCoordinator.tryGetZoneHeart;

    if (heart == null) {
      return await AsyncExecutor(function: () => this).waitResult();
    }

    if (heart.itWasDiscarded) {
      return const  CancelationResult();
    }

    final result = await this;

    if (heart.itWasDiscarded) {
      return const  CancelationResult();
    }

    return result;
  }
}
