import 'dart:async';

import 'package:maxi_framework/maxi_framework.dart';
import 'package:meta/meta.dart';

abstract interface class Functionality<T> {
  AsyncResult<T> execute();

  InteractiveResult<I, T> interactiveExecute<I>();

  Future<Result<T>> executeAsFuture();
}

mixin FunctionalityMixin<T> implements Functionality<T> {
  Oration get functionalityName => FixedOration(message: runtimeType.toString());

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
  void sendText(Oration text) => InteractiveResult.sendItem(text);

  @protected
  ParentController get heart => ParentController.zoneHeart;

  @protected
  bool get isCanceled => heart.itWasDiscarded;

  @override
  Future<Result<T>> executeAsFuture() => execute().waitResult();

  TextableResult<T> textableExecutor() => interactiveExecute<Oration>();

  @override
  InteractiveResult<I, T> interactiveExecute<I>() {
    return InteractiveExecutor<I, T>(function: execute());
  }

  @override
  AsyncExecutor<T> execute() {
    return AsyncExecutor<T>(
      onCancel: onCancel,
      function: () async {
        late Result<T> result;
        try {
          result = await runFuncionality();
          if (result is! CancelationResult) {
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
      },
    );
  }
}
