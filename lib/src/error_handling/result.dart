import 'package:maxi_framework/maxi_framework.dart';

abstract interface class Result<T> {
  bool get itsCorrect;
  bool get itsFailure;
  T get content;
  ErrorData get error;

  Result<R> cast<R>();
  Type get contentType;
}

class ResultValue<T> implements Result<T> {
  @override
  bool get itsCorrect => true;
  @override
  bool get itsFailure => false;

  @override
  final T content;

  @override
  Type get contentType => T;

  const ResultValue({required this.content});

  @override
  ErrorData get error => ControlledFailure(
    errorCode: ErrorCode.implementationFailure,
    message: const FixedOration(message: 'This result is valid, wrong function!'),
  );

  @override
  String toString() => 'Result: $content';

  @override
  Result<R> cast<R>() {
    if (content is R) {
      return ResultValue(content: content as R);
    } else {
      return NegativeResult(
        error: ControlledFailure(
          errorCode: ErrorCode.wrongType,
          message: FlexibleOration(message: 'The result was attempted to be converted to %1, but the content is %2 and is incompatible', textParts: [R, T]),
        ),
      );
    }
  }
}

const voidResult = ResultValue<void>(content: null);

class NegativeResult<T> implements Result<T> {
  @override
  bool get itsCorrect => false;

  @override
  bool get itsFailure => true;

  @override
  Type get contentType => T;

  @override
  final ErrorData error;

  const NegativeResult({required this.error});

  factory NegativeResult.controller({required ErrorCode code, required Oration message}) => NegativeResult(
    error: ControlledFailure(errorCode: code, message: message),
  );

  factory NegativeResult.property({required Oration propertyName, required Oration message}) => NegativeResult(
    error: InvalidProperty(propertyName: propertyName, message: message),
  );

  @override
  T get content => throw error;

  @override
  NegativeResult<R> cast<R>() => NegativeResult<R>(error: error);

  @override
  String toString() => 'Error: ${error.message}';
}

class CancelationResult<T> implements Result<T> {
  @override
  bool get itsCorrect => false;

  @override
  bool get itsFailure => true;

  const CancelationResult();

  @override
  T get content => throw error;

  @override
  Type get contentType => T;

  @override
  ErrorData get error => ControlledFailure(
    errorCode: ErrorCode.functionalityCancelled,
    message: const FixedOration(message: 'The feature has been canceled'),
  );

  @override
  CancelationResult<R> cast<R>() => CancelationResult<R>();

  @override
  String toString() => '<Cancellation error>';
}

class ExceptionResult<T> implements Result<T> {
  final dynamic exception;
  final StackTrace stackTrace;

  @override
  bool get itsCorrect => false;

  @override
  bool get itsFailure => true;

  @override
  T get content => throw error;

  @override
  Type get contentType => T;

  @override
  final ErrorData error;

  ExceptionResult({required this.exception, required this.stackTrace, Oration message = const FixedOration(message: 'An internal error occurred while executing a feature')})
    : error = ControlledFailure(errorCode: ErrorCode.exception, message: message);
  @override
  Result<R> cast<R>() => ExceptionResult<R>(exception: exception, stackTrace: stackTrace, message: error.message);

  @override
  String toString() => '<!> Exception: $exception';
}
