import 'package:maxi_framework/maxi_framework.dart';

extension NativeHexadecimalUtilities on HexadecimalUtilities {
  static Result<void> addDebugging(String direccion, List<int> datos, [String? titulo]) {
    return NegativeResult.controller(
      code: ErrorCode.implementationFailure,
      message: const FixedOration(message: 'The addDebugging method is not implemented for the web platform'),
    );
  }
}
