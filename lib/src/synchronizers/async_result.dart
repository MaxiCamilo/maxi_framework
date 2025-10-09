import 'dart:async';

import 'package:maxi_framework/maxi_framework.dart';

abstract interface class AsyncResult<T> implements Disposable {
  static const kAsyncExecutor = #maxiAsyncResult;

  static bool get isZoneCanceled {
    final executor = Zone.current[kAsyncExecutor];
    if (executor == null) {
      return false;
    }

    if (executor is Disposable) {
      return executor.itWasDiscarded;
    } else {
      return false;
    }
  }

  bool get isActive;

  Future<Result<T>> waitResult();
}
