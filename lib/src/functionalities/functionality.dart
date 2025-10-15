import 'dart:async';

import 'package:maxi_framework/maxi_framework.dart';
import 'package:meta/meta.dart';

abstract interface class Functionality<T> {
  Future<Result<T>> execute();
  AsyncExecutor<T> separateExecution();

  AsyncExecutor<T> interactiveExecution<I>({required void Function(I) onItem});
}

mixin FunctionalityMixin<T> implements Functionality<T> {
  Oration get functionalityName => FixedOration(message: runtimeType.toString());

  @protected
  FutureOr<Result<T>> runFuncionality();

  @protected
  void onError(Result<T> result) {}

  @protected
  void onResultValue(Result<T> result) {}

  @protected
  void onFinish(Result<T> result) {}

  @protected
  Result<T>? onException(dynamic exception, StackTrace stackTrase) => null;

  @protected
  void onCancel() {}

  @protected
  bool sendText(Oration text) {
    InteractiveSystem.sendItem(text);
    return !heart.itWasDiscarded;
  }

  @protected
  LifeCoordinator get heart => LifeCoordinator.zoneHeart;

  @protected
  bool get isCanceled => heart.itWasDiscarded;

  @override
  Future<Result<T>> execute() async {
    late Result<T> result;
    try {
      result = await runFuncionality();
      if (result is CancelationResult) {
        onCancel();
      } else {
        if (result.itsCorrect) {
          onResultValue(result);
        } else {
          onError(result);
        }
      }
    } catch (ex, st) {
      result = ExceptionResult(
        exception: ex,
        stackTrace: st,
        message: FlexibleOration(message: 'An internal error occurred in functionality %1', textParts: [functionalityName]),
      );

      final newResult = onException(ex, st);
      if (newResult != null) {
        result = newResult;
      }
    } finally {
      onFinish(result);
    }

    return result;
  }

  @override
  AsyncExecutor<T> separateExecution() {
    return AsyncExecutor(function: execute);
  }

  @override
  AsyncExecutor<T> interactiveExecution<I>({required void Function(I x) onItem}) {
    return AsyncExecutor(
      function: () => InteractiveSystem.execute<I, Result<T>>(function: execute, onItem: onItem),
    );
  }
}
