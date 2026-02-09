import 'package:maxi_framework/src/conditions/conditionator.dart';

/// Checks if a value is included within a set of values
class CompareIncludeValues implements Conditionator {
  final Object value;
  final Iterable values;

  const CompareIncludeValues(this.value, this.values);

  @override
  bool execute() {
    return values.contains(value);
  }
}
