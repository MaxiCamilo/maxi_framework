import 'package:maxi_framework/maxi_framework.dart';

abstract interface class ErrorData {
  ErrorCode get errorCode;
  Oration get message;
  DateTime get whenWasIt;
}

class ControlledFailure implements ErrorData {
  @override
  final ErrorCode errorCode;

  @override
  final Oration message;

  @override
  final DateTime whenWasIt;

  final StackTrace stackTrace;

  ControlledFailure({required this.errorCode, required this.message, DateTime? whenWasIt, StackTrace? stackTrace}) : whenWasIt = whenWasIt ?? DateTime.now(), stackTrace = stackTrace ?? StackTrace.empty;
}
