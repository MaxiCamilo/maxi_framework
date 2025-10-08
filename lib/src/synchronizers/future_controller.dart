import 'dart:async';

import 'package:maxi_framework/maxi_framework.dart';
import 'package:meta/meta.dart';

abstract interface class FutureControllerContext<T> {
  ParentController get heart;
  bool checkCancelarion();
  Future<bool> checkAsyncCancelarion();

  Result<T> returnCancelation();

  Result<T> ok(T item);
  Result<T> error({required ErrorCode code, required Oration message});
}

class _InternalFutureControllerContext<T> implements FutureControllerContext<T> {
  final FutureController<T> parent;
  @override
  final ParentController heart;

  const _InternalFutureControllerContext({required this.parent, required this.heart});

  @override
  Future<bool> checkAsyncCancelarion() async {
    await Future.delayed(Duration.zero);
    return parent.itWasDiscarded;
  }

  @override
  bool checkCancelarion() {
    return parent.itWasDiscarded;
  }

  @override
  Result<T> returnCancelation() => parent.returnCancelation();

  @override
  Result<T> ok(T item) => PositiveResult(content: item);

  @override
  Result<T> error({required ErrorCode code, required Oration message}) => NegativeResult(
    error: ControlledFailure(errorCode: code, message: message),
  );
}

class FutureController<T> with DisposableMixin, InitializableMixin implements AsyncResult<T> {
  final FutureOr<Result<T>> Function(FutureControllerContext<T> context) function;
  final void Function()? onCancel;
  final void Function(Result<T>)? onDone;

  AsyncResult<void>? _asyncResult;

  ParentController? _genealogicalController;
  StackTrace? _cancelationStack;
  Result<T>? _lastResult;

  FutureController({required this.function, this.onCancel, this.onDone});

  @override
  bool get isActive => _asyncResult != null && _asyncResult!.isActive;

  @override
  Result<void> performInitialization() {
    _lastResult = null;
    _asyncResult?.dispose();
    _asyncResult = FutureWaiter<void>(
      function: _execute,
      onCancel: () => _lastResult = CancelationResult(cancelationStackTrace: StackTrace.current),
    );

    return positiveVoidResult;
  }

  @internal
  Result<T> returnCancelation() {
    if (_cancelationStack == null) {
      return NegativeResult(
        error: ControlledFailure(
          errorCode: ErrorCode.implementationFailure,
          message: const FixedOration(message: 'This feature was not cancelled! Incorrect function call'),
        ),
      );
    } else {
      return CancelationResult(cancelationStackTrace: _cancelationStack!);
    }
  }

  @override
  void performObjectDiscard() {
    if (_asyncResult != null) {
      _cancelationStack = StackTrace.current;

      if (onCancel != null && _lastResult == null) {
        onCancel!();
      }
      _lastResult ??= CancelationResult(cancelationStackTrace: _cancelationStack!);

      _asyncResult!.dispose();
    }
    _genealogicalController?.dispose();

    _asyncResult = null;
    _genealogicalController = null;
  }

  Future<void> _execute() async {
    _cancelationStack = null;
    _genealogicalController = ParentController();

    final engine = _InternalFutureControllerContext(heart: _genealogicalController!, parent: this);

    _lastResult = await function(engine);

    if (onDone != null) {
      onDone!(_lastResult!);
    }
  }

  @override
  Future<Result<T>> waitResult() async {
    initialize();

    await _asyncResult!.waitResult();

    dispose();
    return _lastResult!;
  }
}
