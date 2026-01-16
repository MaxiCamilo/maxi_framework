import 'dart:async';
import 'dart:developer';

import 'package:maxi_framework/maxi_framework.dart';

Future<Result<T>> separateExecution<T>({required FutureOr<Result<T>> Function() function, void Function(LifeCoordinator heart)? onHeartCreated}) async {
  final complete = Completer<Result<T>>();
  scheduleMicrotask(() async {
    final newOperator = AsyncExecutor<T>(function: function, onHeartCreated: onHeartCreated, connectToZone: false);
    final result = await newOperator.waitResult();
    complete.complete(result);
  });

  return complete.future;
}

Future<Result<T>> managedFunction<T>(FutureOr<Result<T>> Function(LifeCoordinator heart) function) async {
  final heart = LifeCoordinator.tryGetZoneHeart;

  if (heart == null) {
    final newOperator = AsyncExecutor<T>(function: () => function(LifeCoordinator.zoneHeart));
    return newOperator.waitResult();
  } else {
    return function(heart);
  }
}

Result<T> volatileFunction<T>({required Result<T> Function(dynamic ex, StackTrace st) error, required T Function() function}) {
  try {
    return ResultValue(content: function());
  } catch (ex, st) {
    return error(ex, st);
  }
}

Future<Result<T>> volatileFuture<T>({required Result<T> Function(dynamic ex, StackTrace st) error, required FutureOr<T> Function() function, FutureOr<void> Function()? onDone, FutureOr<void> Function()? onError}) async {
  bool onDoneCalled = false;
  final heart = LifeCoordinator.tryGetZoneHeart;

  if (heart == null) {
    return managedFunction<T>((heart) => volatileFuture(error: error, function: function, onDone: onDone, onError: onError));
  }

  try {
    if (heart.itWasDiscarded) {
      if (onDone != null) {
        onDoneCalled = true;
        await onDone();
      }
      return CancelationResult();
    }

    final result = ResultValue<T>(content: await function());
    if (onDone != null) {
      onDoneCalled = true;
      await onDone();
    }

    if (heart.itWasDiscarded) {
      return CancelationResult();
    }

    return result;
  } catch (ex, st) {
    if (onDone != null && !onDoneCalled) {
      try {
        await onDone();
      } catch (ex, st) {
        log('[VolatileFuture] Error in onDone! $ex');
        return error(ex, st);
      }
    }

    if (onError != null) {
      try {
        await onError();
      } catch (ex, st) {
        log('[VolatileFuture] Error in onError! $ex');
        return error(ex, st);
      }
    }
    return error(ex, st);
  }
}

extension ExtensionResult<T> on Result<T> {
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
        return ExceptionResult<R>(exception: ex, stackTrace: st);
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

  Result<T> onCorrectLambda(void Function(T x) func) {
    if (itsCorrect) {
      func(content);
    }

    return this;
  }

  Result<R> select<R>(R Function(T x) func) {
    if (itsCorrect) {
      final item = func(content);
      return ResultValue<R>(content: item);
    } else {
      return cast<R>();
    }
  }

  Result<(T, R)> include<R>(R Function(T x) func) {
    if (itsCorrect) {
      try {
        final item = func(content);
        return ResultValue<(T, R)>(content: (content, item));
      } catch (ex, st) {
        return ExceptionResult<(T, R)>(exception: ex, stackTrace: st);
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

  Future<Result<T>> whenItsCorrectVoid(FutureOr<void> Function(T x) func) async {
    if (itsCorrect) {
      final result = await volatileFuture(
        error: (ex, st) => ExceptionResult(exception: ex, stackTrace: st),
        function: () => func(content),
      ).logIfFails();
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
      log(errorName.isEmpty ? error.toString() : '[$errorName] ${error.toString()}');
      log('-----------------------------------------------------');
      log(StackTrace.current.toString());
    }

    return this;
  }

  T exceptionIfFails({required String detail}) {
    if (itsFailure) {
      log(detail);
      log('-----------------------------------------------------');
      log(error.toString());
      log('-----------------------------------------------------');
      log(StackTrace.current.toString());
      throw NegativeResult(error: error);
    }

    return content;
  }
}

extension AllObjectResultExtensions on Object {
  Result<T> asResultValue<T>() => ResultValue(content: this as T);
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
  Future<Result<T>> toFutureResult() async {
    try {
      final value = await this;
      return ResultValue<T>(content: value);
    } catch (ex, st) {
      return ExceptionResult(exception: ex, stackTrace: st);
    }
  }

  Future<Result<T>> makeCancelable({required Duration timeout, Oration message = const FixedOration(message: 'The function took too long and was canceled')}) async {
    final heart = LifeCoordinator.tryGetZoneHeart;
    if (heart == null) {
      return managedFunction(
        (heart) => then<Result<T>>((value) => ResultValue<T>(content: value)).timeout(
          timeout,
          onTimeout: () {
            heart.dispose();
            return NegativeResult<T>.controller(code: ErrorCode.timeout, message: message);
          },
        ),
      );
    } else {
      return then<Result<T>>((value) => ResultValue<T>(content: value)).timeout(
        timeout,
        onTimeout: () {
          heart.dispose();
          return NegativeResult<T>.controller(code: ErrorCode.timeout, message: message);
        },
      );
    }
  }
}

extension FutureResultExtensions<T> on Future<Result<T>> {
  Future<Result<T>> connect() async {
    final heart = LifeCoordinator.tryGetZoneHeart;

    if (heart == null) {
      return await AsyncExecutor(function: () => this).waitResult();
    }

    if (heart.itWasDiscarded) {
      return CancelationResult();
    }

    final result = await this;

    if (heart.itWasDiscarded) {
      return CancelationResult();
    }

    return result;
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
    final item = await this;

    if (item.itsFailure) {
      log(errorName.isEmpty ? item.error.toString() : '[$errorName] ${item.error.toString()}');
      log('-----------------------------------------------------');
      log(StackTrace.current.toString());
    }

    return item;
  }

  Future<Result<T>> cancelIn({required Duration timeout, Oration message = const FixedOration(message: 'The function took too long and was canceled')}) {
    final heart = LifeCoordinator.tryGetZoneHeart;

    if (heart == null) {
      return separateExecution(
        function: () => cancelIn(timeout: timeout, message: message),
      );
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
        return ExceptionResult<R>(exception: ex, stackTrace: st);
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
        return ExceptionResult<T>(exception: ex, stackTrace: st);
      }
    }

    return result;
  }
}

extension FutureOrResultWithoutExtensions<T> on FutureOr<T> {
  FutureOr<Result<T>> asResCatchException({Result<T> Function(dynamic, StackTrace)? onException}) async {
    try {
      return ResultValue<T>(content: await this);
    } catch (ex, st) {
      if (onException == null) {
        return ExceptionResult<T>(exception: ex, stackTrace: st);
      } else {
        return onException(ex, st);
      }
    }
  }
}

extension FutureOrResultExtensions<T> on FutureOr<Result<T>> {
  Future<Result<T>> connect() async {
    final heart = LifeCoordinator.tryGetZoneHeart;

    if (heart == null) {
      return await AsyncExecutor(function: () => this).waitResult();
    }

    if (heart.itWasDiscarded) {
      return CancelationResult();
    }

    final result = await this;

    if (heart.itWasDiscarded) {
      return CancelationResult();
    }

    return result;
  }

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
