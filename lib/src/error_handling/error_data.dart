import 'package:maxi_framework/maxi_framework.dart';

abstract interface class ErrorData {
  ErrorCode get errorCode;
  Oration get message;
}

class ControlledFailure implements ErrorData {
  @override
  final ErrorCode errorCode;

  @override
  final Oration message;

  const ControlledFailure({required this.errorCode, required this.message});
}

class InvalidProperty implements ErrorData {
  @override
  ErrorCode get errorCode => ErrorCode.invalidProperty;

  @override
  final Oration message;

  final Oration propertyName;

  const InvalidProperty({required this.message, required this.propertyName});
}


