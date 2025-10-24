import 'package:maxi_framework/maxi_framework.dart';

abstract interface class Validator {
  Result<void> validateValue({required dynamic value});
}

abstract class SpecificTypeValidator<T> implements Validator {
  const SpecificTypeValidator();

  Result<void> validateWithValue({required T value});

  @override
  Result<void> validateValue({required dynamic value}) {
    if (value is T) {
      return validateWithValue(value: value);
    } else {
      if (value == null) {
        return NegativeResult.controller(
          code: ErrorCode.invalidValue,
          message: FixedOration(message: 'No null values accepted'),
        );
      } else {
        return NegativeResult.controller(
          code: ErrorCode.invalidValue,
          message: FlexibleOration(message: 'Expected a value of type %1, but received a value of type %2', textParts: [T, value.runtimeType]),
        );
      }
    }
  }
}
