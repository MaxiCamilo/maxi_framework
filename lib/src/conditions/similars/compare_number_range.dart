import 'package:maxi_framework/maxi_framework.dart';

class CompareNumberRange implements Conditionator {
  final num number;
  final num min;
  final num max;

  const CompareNumberRange({required this.number, required this.min, required this.max});

  @override
  bool execute() {
    if (min > max) {
      throw ArgumentError('Min value cannot be greater than max value');
    }

    if (min == double.negativeInfinity || max == double.infinity) {
      return true;
    }

    if (max == double.infinity) {
      return number >= min;
    }

    if (min == double.negativeInfinity) {
      return number <= max;
    }

    return number >= min && number <= max;
  }
}
