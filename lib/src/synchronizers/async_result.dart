import 'dart:async';

import 'package:maxi_framework/maxi_framework.dart';

abstract interface class AsyncResult<T> implements Disposable {
  bool get isActive;

  Future<Result<T>> waitResult();
}




