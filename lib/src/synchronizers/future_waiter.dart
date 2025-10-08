import 'dart:async';
import 'dart:developer';

import 'package:maxi_framework/maxi_framework.dart';

class FutureWaiter<T> with DisposableMixin implements AsyncResult<T> {
  final Future<T> Function() _function;
  final Result? Function()? onCancel;
  final void Function(Result<T>)? onDone;

  Completer<Result<T>>? _completer;

  FutureWaiter({required Future<T> Function() function, this.onCancel, this.onDone}) : _function = function;

  @override
  bool get isActive => _completer != null && !_completer!.isCompleted;

  @override
  void performResurrection() {
    super.performResurrection();
    _completer = null;
  }

  @override
  Future<Result<T>> waitResult() async {
    if (_completer != null) {
      return _completer!.future;
    }

    if (itWasDiscarded) {
      return NegativeResult(
        error: ControlledFailure(
          errorCode: ErrorCode.implementationFailure,
          message: FixedOration(message: 'The waiter was canceled'),
        ),
      );
    }

    final completer = Completer<Result<T>>();
    _completer = completer;

    late final Result<T> result;

    try {
      result = PositiveResult<T>(content: await _function());
      if (!completer.isCompleted) {
        completer.complete(result);
      }
    } catch (ex, st) {
      log('Exception detected!: $ex');
      log('------------------------------------------------------------------');
      log(st.toString());
      log('------------------------------------------------------------------');
      result = ExceptionResult<T>(exception: ex, stackTrace: st);
      if (!completer.isCompleted) {
        completer.complete(result);
      }
    }

    if (onDone != null) {
      onDone!(result);
    }

    dispose();
    return result;
  }

  @override
  void performObjectDiscard() {
    if (_completer != null && !_completer!.isCompleted) {
      late final Result error;
      if (onCancel == null) {
        error = CancelationResult(cancelationStackTrace: StackTrace.current);
      } else {
        try {
          final returnedError = onCancel!();
          error = returnedError ?? CancelationResult(cancelationStackTrace: StackTrace.current);
        } catch (ex, st) {
          error = ExceptionResult(exception: ex, stackTrace: st);
        }
      }

      _completer!.complete(error.cast<T>());
    }
  }
}

class FuturePackWaiter<T> with DisposableMixin implements AsyncResult<T> {
  final Future<Result<T>> Function() _function;
  final Result? Function()? onCancel;
  final void Function(Result<T>)? onDone;

  Completer<Result<T>>? _completer;

  FuturePackWaiter({required Future<Result<T>> Function() function, this.onCancel, this.onDone}) : _function = function;

  @override
  bool get isActive => _completer != null && !_completer!.isCompleted;

  @override
  void performResurrection() {
    super.performResurrection();
    _completer = null;
  }

  @override
  Future<Result<T>> waitResult() async {
    if (_completer != null) {
      return _completer!.future;
    }

    if (itWasDiscarded) {
      return NegativeResult(
        error: ControlledFailure(
          errorCode: ErrorCode.implementationFailure,
          message: FixedOration(message: 'The waiter was canceled'),
        ),
      );
    }

    final completer = Completer<Result<T>>();
    _completer = completer;

    late final Result<T> result;

    try {
      result =  await _function();
      if (!completer.isCompleted) {
        completer.complete(result);
      }
    } catch (ex, st) {
      log('Exception detected!: $ex');
      log('------------------------------------------------------------------');
      log(st.toString());
      log('------------------------------------------------------------------');
      result = ExceptionResult<T>(exception: ex, stackTrace: st);
      if (!completer.isCompleted) {
        completer.complete(result);
      }
    }

    if (onDone != null) {
      onDone!(result);
    }

    dispose();
    return result;
  }

  @override
  void performObjectDiscard() {
    if (_completer != null && !_completer!.isCompleted) {
      late final Result error;
      if (onCancel == null) {
        error = CancelationResult(cancelationStackTrace: StackTrace.current);
      } else {
        try {
          final returnedError = onCancel!();
          error = returnedError ?? CancelationResult(cancelationStackTrace: StackTrace.current);
        } catch (ex, st) {
          error = ExceptionResult(exception: ex, stackTrace: st);
        }
      }

      _completer!.complete(error.cast<T>());
    }
  }
}
