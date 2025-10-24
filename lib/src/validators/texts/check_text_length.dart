import 'package:maxi_framework/maxi_framework.dart';

class CheckTextLength extends SpecificTypeValidator<String> {
  final num maximum;
  final num minimum;

  const CheckTextLength({this.minimum = 0, this.maximum = double.infinity});

  @override
  Result<void> validateWithValue({required String value}) {
    if (value.length < minimum) {
      if (value.isEmpty) {
        return NegativeResult.controller(
          code: ErrorCode.invalidValue,
          message: FlexibleOration(message: 'The text is required to have a minimum of %1 characters to be valid, but the text is empty', textParts: [minimum]),
        );
      } else {
        return NegativeResult.controller(
          code: ErrorCode.invalidValue,
          message: FlexibleOration(message: 'The text is required to have a minimum of %1 characters to be valid, but the text has %2 characters', textParts: [minimum, value.length]),
        );
      }
    }

    if (value.length > maximum) {
      return NegativeResult.controller(
        code: ErrorCode.invalidValue,
        message: FlexibleOration(message: 'Only texts with a maximum of %1 characters are allowed, but the text has %2 characters', textParts: [maximum, value.length]),
      );
    }

    return voidResult;
  }
}
