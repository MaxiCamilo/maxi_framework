import 'dart:async';

import 'package:maxi_framework/maxi_framework.dart';
import 'package:meta/meta.dart';

abstract interface class Functionality<T> {
  AsyncResult<T> execute();

  Future<Result<T>> executeAsFuture();
}

mixin FunctionalityMixin<T> implements Functionality<T> {
  Oration get functionalityName => FixedOration(message: runtimeType.toString());

  FutureOr<Result<T>> runFuncionality(FutureControllerContext<T> context);

  @protected
  void onError(Result<T> result) {}

  @protected
  void onPositiveResult(Result<T> result) {}

  @protected
  void onFinish(Result<T> result) {}

  @protected
  Result<T>? onException(dynamic exception, StackTrace stackTrase) => null;

  @protected
  void onCancel() {}

  @override
  Future<Result<T>> executeAsFuture() => execute().waitResult();

  @override
  AsyncResult<T> execute() {
    return FutureController<T>(
      onCancel: onCancel,
      function: (context) async {
        late Result<T> result;
        try {
          result = await runFuncionality(context);
          if (!context.heart.itWasDiscarded) {
            if (result.itsCorrect) {
              onPositiveResult(result);
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
