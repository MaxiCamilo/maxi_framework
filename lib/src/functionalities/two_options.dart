import 'package:maxi_framework/maxi_framework.dart';

class TwoOptions<T1 extends Object, T2 extends Object> {
  final Object _value;

  bool get isFirst => _value is T1;
  bool get isSecond => _value is T2;

  TwoOptions._(this._value);

  factory TwoOptions.first(T1 value) {
    return TwoOptions._(value);
  }

  factory TwoOptions.second(T2 value) {
    return TwoOptions._(value);
  }

  Result<T1> get first {
    if (isFirst) {
      return (_value as T1).asResultValue();
    } else {
      return NegativeResult.controller(
        code: ErrorCode.implementationFailure,
        message: const FixedOration(message: 'The value is not of the first type'),
      );
    }
  }

  Result<T2> get second {
    if (isSecond) {
      return (_value as T2).asResultValue();
    } else {
      return NegativeResult.controller(
        code: ErrorCode.implementationFailure,
        message: const FixedOration(message: 'The value is not of the second type'),
      );
    }
  }
}
