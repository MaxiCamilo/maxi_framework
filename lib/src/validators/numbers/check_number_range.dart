import 'package:maxi_framework/maxi_framework.dart';

class CheckNumberRange extends SpecificTypeValidator<num> {
  final num maximum;
  final num minimum;

  const CheckNumberRange({this.minimum = 0, this.maximum = double.infinity});

  @override
  Result<void> validateWithValue({required num value}) {
    if (value < minimum) {
      if (value < 0 && minimum >= 0) {
        return NegativeResult.controller(
          code: ErrorCode.invalidValue,
          message: FixedOration(message: 'Negative numbers are not accepted'),
        );
      }
      if (value == 0) {
        return NegativeResult.controller(
          code: ErrorCode.invalidValue,
          message: FixedOration(message: 'Zero is not allowed'),
        );
      } else {
        return NegativeResult.controller(
          code: ErrorCode.invalidValue,
          message: FlexibleOration(message: 'The number %1 is not accepted because the limit is %2', textParts: [value, maximum]),
        );
      }
    }

    return voidResult;
  }
}
