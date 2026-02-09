import 'package:maxi_framework/src/conditions/conditionator.dart';

/// Compares two values based on the specified comparison type
class CompareValues implements Conditionator {
  final Object first;
  final Object second;
  final ConditionCompareType compareType;

  const CompareValues(this.first, this.second, this.compareType);

  factory CompareValues.equal(Object first, Object second) {
    return CompareValues(first, second, ConditionCompareType.equal);
  }

  factory CompareValues.notEqual(Object first, Object second) {
    return CompareValues(first, second, ConditionCompareType.notEqual);
  }

  factory CompareValues.greater(Object first, Object second) {
    return CompareValues(first, second, ConditionCompareType.greater);
  }

  factory CompareValues.less(Object first, Object second) {
    return CompareValues(first, second, ConditionCompareType.less);
  }

  factory CompareValues.greaterEqual(Object first, Object second) {
    return CompareValues(first, second, ConditionCompareType.greaterEqual);
  }

  factory CompareValues.lessEqual(Object first, Object second) {
    return CompareValues(first, second, ConditionCompareType.lessEqual);
  }

  @override
  bool execute() {
    switch (compareType) {
      case ConditionCompareType.equal:
        return first == second;
      case ConditionCompareType.notEqual:
        return first != second;
      case ConditionCompareType.greater:
        if (first is Comparable && second is Comparable) {
          return (first as Comparable).compareTo(second) > 0;
        }
        throw ArgumentError('Values must be comparable for greater comparison');
      case ConditionCompareType.less:
        if (first is Comparable && second is Comparable) {
          return (first as Comparable).compareTo(second) < 0;
        }
        throw ArgumentError('Values must be comparable for less comparison');
      case ConditionCompareType.greaterEqual:
        if (first is Comparable && second is Comparable) {
          return (first as Comparable).compareTo(second) >= 0;
        }
        throw ArgumentError('Values must be comparable for greater equal comparison');
      case ConditionCompareType.lessEqual:
        if (first is Comparable && second is Comparable) {
          return (first as Comparable).compareTo(second) <= 0;
        }
        throw ArgumentError('Values must be comparable for less equal comparison');
    }
  }
}
