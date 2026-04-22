import 'package:maxi_framework/maxi_framework.dart';

class CheckListMustNotEmpty extends SpecificTypeValidator<Iterable> {
  const CheckListMustNotEmpty();

  @override
  Result<void> validateWithValue({required Iterable<dynamic> value}) {
    if (value.isEmpty) {
      return NegativeResult.controller(
        code: ErrorCode.invalidValue,
        message: const FixedOration(message: 'The list cannot be empty'),
      );
    }
    return voidResult;
  }
}
