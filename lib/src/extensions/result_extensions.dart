import 'dart:async';
import 'dart:developer';

import 'package:maxi_framework/maxi_framework.dart';

Result<T> tryFunction<T>(Oration message, T Function() func) {
  try {
    return ResultValue(content: func());
  } catch (ex, st) {
    appManager.exceptionChannel.sendItem((ex, st));
    return ExceptionResult(exception: ex, stackTrace: st, message: message);
  }
}

Result<T> tryCast<T>(Oration message, dynamic value) {
  if (value == null) {
    return NegativeResult.controller(code: ErrorCode.nullValue, message: message);
  }
  if (value is T) {
    return ResultValue(content: value);
  } else {
    return NegativeResult.controller(
      code: ErrorCode.wrongType,
      message: FlexibleOration(message: '%1. Expected type: %2, but was %3', textParts: [message, T, value.runtimeType]),
    );
  }
}

Result<T> volatileFunction<T>({required Result<T> Function(dynamic ex, StackTrace st) error, required T Function() function}) {
  try {
    return ResultValue(content: function());
  } catch (ex, st) {
    appManager.exceptionChannel.sendItem((ex, st));
    return error(ex, st);
  }
}

FutureResult<T> volatileFuture<T>({required Result<T> Function(dynamic ex, StackTrace st) error, required FutureOr<T> Function() function}) async {
  try {
    final future = await function();
    return ResultValue(content: future);
  } catch (ex, st) {
    final resultError = error(ex, st);
    appManager.exceptionChannel.sendItem((ex, st));
    return resultError;
  }
}

FutureResult<T> separateExecution<T>({required FutureOr<Result<T>> Function() function, void Function(AsyncExecutor)? onExecuted}) async {
  final completer = Completer<Result<T>>();

  scheduleMicrotask(() async {
    final asynExecutor = AsyncExecutor(function: function, connectToZone: false);
    if (onExecuted != null) onExecuted(asynExecutor);
    final result = await asynExecutor.waitResult();
    completer.complete(result);
  });

  return completer.future;
}

extension ExtensionResult<T> on Result<T> {
  Result<T> checkCancelation() {
    if (itsFailure) {
      return this;
    }

    if (LifeCoordinator.isZoneHeartCanceled) {
      final cancel = CancelationResult<T>();
      appManager.exceptionChannel.sendItem((cancel, StackTrace.current));
      return cancel;
    }

    return this;
  }

  Result<R> whenCast<I, R>(Result<R> Function(I) func) {
    if (itsFailure) return cast<R>();

    if (content is I) {
      return func(content as I);
    } else {
      return NegativeResult.controller(
        code: ErrorCode.wrongType,
        message: FlexibleOration(message: 'It is not possible to convert the result %1 to %2', textParts: [content.runtimeType, I]),
      );
    }
  }

  Result<R> changeValueResult<R>(R Function(T x) func) {
    if (itsCorrect) {
      try {
        final item = func(content);
        return ResultValue<R>(content: item);
      } catch (ex, st) {
        return ExceptionResult<R>(
          exception: ex,
          stackTrace: st,
          message: FlexibleOration(message: 'It is not possible to change the result value, as it is not compatible: %1', textParts: [ex]),
        );
      }
    } else {
      return cast<R>();
    }
  }

  Future<Result<R>> whenFutureCast<I, R>(FutureOr<Result<R>> Function(I x) func) async {
    if (itsFailure) return cast<R>();

    if (content is I) {
      return await func(content as I);
    } else {
      return NegativeResult.controller(
        code: ErrorCode.wrongType,
        message: FlexibleOration(message: 'It is not possible to convert the result %1 to %2', textParts: [content.runtimeType, I]),
      );
    }
  }

  Result<R> onCorrect<R>(Result<R> Function(T x) func) {
    if (itsCorrect) {
      return func(content);
    } else {
      return cast<R>();
    }
  }

  Result<R> select<R>(R Function(T x) func) {
    if (itsCorrect) {
      final item = func(content);
      return ResultValue<R>(content: item);
    } else {
      return cast<R>();
    }
  }

  Result<void> selectVoid(void Function(T x) func) {
    if (itsCorrect) {
      func(content);
      return voidResult;
    } else {
      return cast<void>();
    }
  }

  Result<(T, R)> include<R>(R Function(T x) func) {
    if (itsCorrect) {
      try {
        final item = func(content);
        return ResultValue<(T, R)>(content: (content, item));
      } catch (ex, st) {
        return ExceptionResult<(T, R)>(
          exception: ex,
          stackTrace: st,
          message: FlexibleOration(message: 'It is not possible to include the result value, as it is not compatible: %1', textParts: [ex]),
        );
      }
    } else {
      return cast<(T, R)>();
    }
  }

  Result<(T, R)> includeResult<R>(Result<R> Function(T x) func) {
    if (itsCorrect) {
      final item = func(content);
      if (item.itsFailure) {
        return item.cast<(T, R)>();
      }
      return ResultValue<(T, R)>(content: (content, item.content));
    } else {
      return cast<(T, R)>();
    }
  }

  Future<Result<R>> onCorrectFuture<R>(FutureOr<Result<R>> Function(T x) func) async {
    if (itsCorrect) {
      return await func(content);
    } else {
      return cast<R>();
    }
  }

  Future<Result<T>> whenItsCorrect(FutureOr<Result<void>> Function(T x) func) async {
    if (itsCorrect) {
      final result = await func(content);
      return result.itsCorrect ? this : result.cast<T>();
    } else {
      return cast<T>();
    }
  }

  Result<void> ignoreContent() {
    if (itsCorrect) {
      return voidResult;
    } else {
      return cast<void>();
    }
  }

  Result<T> logIfFails({String errorName = ''}) {
    if (itsFailure) {
      Future.delayed(Duration.zero);
      log('''#############################################################
      ${errorName.isEmpty ? error.toString() : '[$errorName] ${error.toString()}'}
      -----------------------------------------------------
      ${StackTrace.current.toString()}
      #############################################################''');
    }

    return this;
  }

  Result<T> onErrorAddMessage(Oration message) {
    if (itsFailure) {
      return NegativeResult(
        error: ControlledFailure(
          errorCode: error.errorCode,
          message: FlexibleOration(message: '%1. %2', textParts: [message, error.message]),
        ),
      );
    } else {
      return this;
    }
  }

  Result<T> onErrorInsertPartialResult({required T partialResult}) {
    if (itsFailure) {
      return NegativePartialResult<T>(error: error, partialContent: partialResult);
    } else {
      return this;
    }
  }

  T exceptionIfFails({required String detail}) {
    if (itsFailure) {
      appManager.exceptionChannel.sendItem((error, StackTrace.current));
      log('''#############################################################
      FATAL EXCEPTION!!${detail.isEmpty ? '' : ': "$detail"'}
      -----------------------------------------------------
      ${StackTrace.current.toString()}
      #############################################################''');
      throw NegativeResult(error: error);
    }

    return content;
  }

  Result<T> injectLogic(Result<void> Function(T) function) {
    if (itsFailure) {
      return this;
    }

    final logicResult = function(content);
    if (logicResult.itsFailure) {
      return logicResult.cast<T>();
    }

    return this;
  }

  Result<T> injectVoidLogic(void Function(T) function) {
    if (itsFailure) {
      return this;
    }

    tryFunction(const FixedOration(message: 'An error occurred while executing the injected logic'), () => function(content));

    return this;
  }

  Result<T> injectNegativeLogic(Result<void> Function(Result<T>) function) {
    if (itsCorrect) {
      return this;
    }

    final logicResult = function(this);
    if (logicResult.itsFailure) {
      return logicResult.cast<T>();
    }

    return this;
  }
}

extension AllObjectResultExtensions on Object {
  Result<T> asResultValue<T>() => ResultValue(content: this as T);

  Result<T> dynamicCastResult<T>({Oration? errorMessage}) {
    if (this is T) {
      return ResultValue(content: this as T);
    } else {
      return NegativeResult.controller(
        code: ErrorCode.wrongType,
        message: errorMessage ?? FlexibleOration(message: 'It is not possible to convert the result %1 to %2', textParts: [runtimeType, T]),
      );
    }
  }
}

extension AllNullabletResultExtensions on Object? {
  Result<T> asResIfItsNull<T>(Result<T> Function() function) {
    if (this == null) {
      return function();
    } else {
      return this!.asResultValue<T>();
    }
  }

  Result<T> asResErrorIfItsNull<T>({ErrorCode code = ErrorCode.nullValue, required Oration message}) {
    if (this == null) {
      return NegativeResult<T>.controller(code: code, message: message);
    } else if (this is Result) {
      if ((this as Result).itsFailure) return (this as Result).cast();
      if ((this as Result).content == null) {
        return NegativeResult<T>.controller(code: code, message: message);
      } else {
        return (this as Result).cast<T>();
      }
    } else {
      return this!.asResultValue<T>();
    }
  }
}

extension FutureWithoutResultExtensions<T> on Future<T> {
  Future<Result<T>> toFutureResult({Oration? errorMessage}) async {
    try {
      final value = await this;
      return ResultValue<T>(content: value);
    } catch (ex, st) {
      appManager.exceptionChannel.sendItem((ex, st));
      return ExceptionResult<T>(
        exception: ex,
        stackTrace: st,
        message: errorMessage ?? const FixedOration(message: 'Internal error: A chained asynchronous function failed'),
      );
    }
  }
}

extension FutureResultExtensions<T> on Future<Result<T>> {
  Future<Result<T>> separateExecution() {
    final completer = Completer<Result<T>>();

    scheduleMicrotask(() async {
      final asynExecutor = AsyncExecutor(function: () => this, connectToZone: false);
      final result = await asynExecutor.waitResult();
      completer.complete(result);
    });

    return completer.future;
  }

  Future<Result<T>> checkCancelation() async {
    if (LifeCoordinator.isZoneHeartCanceled) {
      final cancel = CancelationResult<T>();
      appManager.exceptionChannel.sendItem((cancel, StackTrace.current));
      return cancel;
    }

    final result = await this;
    if (result.itsCorrect && LifeCoordinator.isZoneHeartCanceled) {
      final cancel = CancelationResult<T>();
      appManager.exceptionChannel.sendItem((cancel, StackTrace.current));
      return cancel;
    }

    return result;
  }

  Future<Result<T>> breakIfCanceled({FutureOr<void> Function()? onCancel}) async {
    if (LifeCoordinator.isZoneHeartCanceled) {
      return CancelationResult<T>();
    }

    final heart = LifeCoordinator.tryGetZoneHeart;
    if (heart != null) {
      if (heart.itWasDiscarded) {
        final cancel = CancelationResult<T>();
        appManager.exceptionChannel.sendItem((cancel, StackTrace.current));
        return cancel;
      }
      final completer = Completer<Result<T>>();
      final onDone = heart.onDispose.whenComplete(() {
        if (!completer.isCompleted) {
          final cancel = CancelationResult<T>();
          appManager.exceptionChannel.sendItem((cancel, StackTrace.current));
          completer.complete(cancel);
        }
      });

      final result = await this;
      onDone.ignore();

      return result;
    } else {
      final result = await this;
      return result;
    }
  }

  Future<Result<R>> castFuture<R>() async {
    final content = await this;
    if (content.itsCorrect) {
      if (content.content is R) {
        return ResultValue(content: content.content as R);
      } else {
        return NegativeResult(
          error: ControlledFailure(
            errorCode: ErrorCode.wrongType,
            message: FlexibleOration(message: 'The result was attempted to be converted to %1, but the content is %2 and is incompatible', textParts: [R, T]),
          ),
        );
      }
    } else {
      return content.cast<R>();
    }
  }

  Future<Result<T>> logIfFails({String errorName = ''}) async {
    late final Result<T> item;

    try {
      item = await this;
    } catch (ex, st) {
      item = ExceptionResult<T>(
        exception: ex,
        stackTrace: st,
        message: errorName.isEmpty
            ? const FixedOration(message: 'An exception was thrown while waiting for the future result')
            : FlexibleOration(message: 'An exception was thrown while waiting for the future result: %1', textParts: [errorName]),
      );
    }

    if (item.itsFailure) {
      log('''#############################################################
      ${errorName.isEmpty ? item.error.toString() : '[$errorName] ${item.error.toString()}'}
      -----------------------------------------------------
      ${item is ResultHasStack ? (item as ResultHasStack).stackTrace.toString() : StackTrace.current.toString()}
      #############################################################''');
    }

    return item;
  }

  Future<Result<T>> cancelIn({required Duration timeout, Oration message = const FixedOration(message: 'The function took too long and was canceled')}) {
    final heart = LifeCoordinator.tryGetZoneHeart;

    if (heart == null) {
      return separateExecution().cancelIn(timeout: timeout, message: message);
    } else {
      return this.timeout(
        timeout,
        onTimeout: () {
          heart.dispose();
          return NegativeResult.controller(code: ErrorCode.timeout, message: message);
        },
      );
    }
  }

  Future<Result<R>> onCorrectFuture<R>(FutureOr<Result<R>> Function(T x) func) async {
    final result = await this;
    if (result.itsCorrect) {
      return await func(result.content);
    } else {
      return result.cast<R>();
    }
  }

  Future<Result<R>> selectFuture<R>(FutureOr<R> Function(T x) func) async {
    final result = await this;
    if (result.itsCorrect) {
      try {
        return ResultValue<R>(content: await func(result.content));
      } catch (ex, st) {
        return ExceptionResult<R>(
          exception: ex,
          stackTrace: st,
          message: const FixedOration(message: 'Internal error: A chained asynchronous function failed'),
        );
      }
    } else {
      return result.cast<R>();
    }
  }

  Future<Result<void>> onCorrectFutureVoid(FutureOr<void> Function(T x) func) async {
    final result = await this;
    if (result.itsCorrect) {
      await func(result.content);
      return voidResult;
    } else {
      return result.cast<void>();
    }
  }

  Future<Result<T>> onNegativeFuture(FutureOr<Result<T>> Function(ErrorData error) func) async {
    final result = await this;
    if (result.itsCorrect) {
      return result;
    } else {
      return await func(result.error);
    }
  }

  Future<Result<T>> catchNegativeFuture(FutureOr<void> Function(ErrorData error) func) async {
    final result = await this;
    if (result.itsFailure) {
      try {
        await func(result.error);
      } catch (ex, st) {
        return ExceptionResult<T>(
          exception: ex,
          stackTrace: st,
          message: const FixedOration(message: 'Internal error: A chained asynchronous function failed while handling an error'),
        );
      }
    }

    return result;
  }

  Future<Result<T>> injectLogic(FutureOr<Result<void>> Function(T) function) async {
    final result = await this;
    if (result.itsFailure) {
      return result;
    }

    final logicResult = await function(result.content);
    if (logicResult.itsFailure) {
      return logicResult.cast<T>();
    }

    return result;
  }

  Future<Result<T>> injectNegativeLogic(FutureOr<void> Function(NegativeResult<T>) function) async {
    final result = await this;
    if (result.itsCorrect) {
      return result;
    }

    await function(result as NegativeResult<T>);

    return result;
  }

  Future<Result<T>> onErrorInsertPartialResult({required T partialResult}) async {
    final result = await this;
    if (result.itsFailure) {
      return NegativePartialResult(error: result.error, partialContent: partialResult);
    } else {
      return result;
    }
  }

  Future<Result<T>> tryWhenNegative(FutureOr<Result<T>> Function(NegativeResult<T>) function) async {
    final result = await this;
    if (result.itsCorrect) {
      return result;
    }

    return await function(result as NegativeResult<T>);
  }

  Future<T> waitContentOrThrow() async {
    final result = await this;
    if (result.itsCorrect) {
      return result.content;
    } else {
      log('''#############################################################
      FATAL EXCEPTION!! The asynchronous function returned an error result that was not handled!
      -----------------------------------------------------
      ${result.error.toString()}
      ${result is ResultHasStack ? (result as ResultHasStack).stackTrace.toString() : StackTrace.current.toString()}
      #############################################################''');
      throw NegativeResult(error: result.error);
    }
  }

  Future<Result<T>> setTimeoutError({required Duration timeout, Oration message = const FixedOration(message: 'The function took too long and was canceled')}) {
    final heart = LifeCoordinator.tryGetZoneHeart;

    if (heart == null) {
      return separateExecution().setTimeoutError(timeout: timeout, message: message);
    } else {
      return this.timeout(
        timeout,
        onTimeout: () {
          heart.dispose();
          return NegativeResult.controller(code: ErrorCode.timeout, message: message);
        },
      );
    }
  }
}

extension FutureOrResultWithoutExtensions<T> on FutureOr<T> {
  FutureOr<Result<T>> asResCatchException({Result<T> Function(dynamic, StackTrace)? onException}) async {
    try {
      return ResultValue<T>(content: await this);
    } catch (ex, st) {
      if (onException == null) {
        return ExceptionResult<T>(
          exception: ex,
          stackTrace: st,
          message: const FixedOration(message: 'Internal error: A chained function failed while processing an exception'),
        );
      } else {
        return onException(ex, st);
      }
    }
  }

  FutureOr<Result<T>> asFutOptResValue({Result<T> Function(dynamic, StackTrace)? onException}) async {
    final value = await this;
    try {
      return ResultValue<T>(content: value);
    } catch (ex, st) {
      if (onException == null) {
        return ExceptionResult<T>(
          exception: ex,
          stackTrace: st,
          message: const FixedOration(message: 'Internal error: A chained function failed while processing an exception'),
        );
      } else {
        return onException(ex, st);
      }
    }
  }
}

extension FutureOrResultExtensions<T> on FutureOr<Result<T>> {
  Future<Result<void>> ignoreFutureContent() async {
    final result = await this;
    if (result.itsCorrect) {
      return voidResult;
    } else {
      return result.cast<void>();
    }
  }

  Future<Result<T>> asFutureResult() async {
    final result = await this;
    if (result.itsCorrect) {
      return result;
    } else {
      return result.cast<T>();
    }
  }
}
