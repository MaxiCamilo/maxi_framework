import 'dart:async';

import 'package:maxi_framework/maxi_framework.dart';
import 'package:meta/meta.dart';

abstract interface class Functionality<T> {
  Future<Result<T>> execute();
  Future<Result<T>> separateExecution();

  AsyncExecutor<T> interactiveExecution<I>({required void Function(I) onItem});
}

mixin FunctionalityMixin<T> implements Functionality<T> {
  Oration get functionalityName => FixedOration(message: runtimeType.toString());

  @protected
  FutureOr<Result<T>> runInternalFuncionality();

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
  void onReset() {}

  @protected
  bool sendText(Oration text) {
    InteractiveSystem.sendItem(text);
    return !LifeCoordinator.isZoneHeartCanceled;
  }

  @protected
  LifeCoordinator get heart => LifeCoordinator.zoneHeart;

  @protected
  bool get isCanceled => LifeCoordinator.isZoneHeartCanceled;

  @override
  Future<Result<T>> execute() async {
    late Result<T> result;
    try {
      result = await runInternalFuncionality();
      if (result is CancelationResult) {
        appManager.exceptionChannel.sendItem((result, StackTrace.current));
        onCancel();
      } else {
        if (result.itsCorrect) {
          onResultValue(result);
        } else {
          onError(result);
        }
      }
    } catch (ex, st) {
      appManager.exceptionChannel.sendItem((ex, st));
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
      tryFunction(FlexibleOration(message: 'An internal error occurred to invoke onFinish in functionality %1', textParts: [functionalityName]), () => onFinish(result));
    }

    return result;
  }

  @override
  Future<Result<T>> separateExecution() {
    return AsyncExecutor(function: execute).waitResult();
  }

  @override
  AsyncExecutor<T> interactiveExecution<I>({required void Function(I x) onItem}) {
    final exe = AsyncExecutor(function: execute);
    exe.messages<I>().listen(onItem);

    return exe;
  }
}

abstract class FunctionalityHeart<T> with FunctionalityMixin<T> {
  const FunctionalityHeart();

  FutureResult<T> runFuncionalityWithHeart(LifeCoordinator heart);

  @protected
  @override
  FutureResult<T> runInternalFuncionality() async {
    if (LifeCoordinator.isZoneHeartCanceled) {
      return CancelationResult();
    }

    if (LifeCoordinator.hasZoneHeart) {
      return await runFuncionalityWithHeart(LifeCoordinator.zoneHeart);
    } else {
      return await AsyncExecutor(function: () => runFuncionalityWithHeart(LifeCoordinator.zoneHeart), connectToZone: true).waitResult();
    }
  }
}
