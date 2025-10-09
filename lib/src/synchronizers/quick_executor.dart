import 'dart:async';

import 'package:maxi_framework/maxi_framework.dart';

AsyncResult<T> quickAsyncResult<T>(FutureOr<Result<T>> Function() function) => _QuickExecutor<T>(function: function);
AsyncResult<T> quickAsyncFunction<T>(FutureOr<T> Function() function) => _QuickFunction<T>(function: function);

class _QuickExecutor<T> with DisposableMixin implements AsyncResult<T> {
  final FutureOr<Result<T>> Function() function;

  Disposable? _heart;

  _QuickExecutor({required this.function});

  @override
  bool get isActive => _heart != null && !_heart!.itWasDiscarded;

  @override
  Future<Result<T>> waitResult() async {
    late final Result<T> result;
    if (ParentController.hasZoneHeart) {
      result = await function();
    } else {
      final newOperator = AsyncExecutor<T>(function: function);
      _heart = newOperator;
      result = await newOperator.waitResult();
      dispose();
    }

    return result;
  }

  @override
  void performObjectDiscard() {
    _heart?.dispose();
    _heart = null;
  }
}

class _QuickFunction<T> with DisposableMixin implements AsyncResult<T> {
  final FutureOr<T> Function() function;

  Disposable? _heart;

  _QuickFunction({required this.function});

  @override
  bool get isActive => _heart != null && !_heart!.itWasDiscarded;

  @override
  Future<Result<T>> waitResult() async {
    if (ParentController.hasZoneHeart) {
      return ResultValue(content: await function());
    } else {
      final newOperator = AsyncExecutor<T>.function(function: function);
      _heart = newOperator;
      final result = await newOperator.waitResult();
      dispose();

      return result;
    }
  }

  @override
  void performObjectDiscard() {
    _heart?.dispose();
    _heart = null;
  }
}
