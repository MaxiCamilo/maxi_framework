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

  @override
  String toString() => '[ID $errorCode] $message';
}

class InvalidProperty implements ErrorData {
  @override
  ErrorCode get errorCode => ErrorCode.invalidProperty;

  @override
  final Oration message;

  final Oration propertyName;

  const InvalidProperty({required this.message, required this.propertyName});
}

class InvalidEntity implements ErrorData {
  @override
  ErrorCode get errorCode => ErrorCode.invalidValue;

  @override
  Oration get message => FlexibleOration(message: 'The entity %1 is invalid due to the following properties: %2', textParts: [entityName, invalidProperties.map((p) => p.propertyName).toList()]);

  final List<InvalidProperty> invalidProperties;

  final Oration entityName;

  const InvalidEntity({required this.entityName, required this.invalidProperties});
}
