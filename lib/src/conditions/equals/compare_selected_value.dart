import 'dart:developer';

import 'package:maxi_framework/maxi_framework.dart';

class CompareSelectedValue implements Conditionator {
  final Object value;
  final ConditionCompareType compareType;

  const CompareSelectedValue({required this.value, required this.compareType});

  factory CompareSelectedValue.equal(Object value) {
    return CompareSelectedValue(value: value, compareType: ConditionCompareType.equal);
  }

  factory CompareSelectedValue.notEqual(Object value) {
    return CompareSelectedValue(value: value, compareType: ConditionCompareType.notEqual);
  }

  factory CompareSelectedValue.greater(Object value) {
    return CompareSelectedValue(value: value, compareType: ConditionCompareType.greater);
  }

  factory CompareSelectedValue.less(Object value) {
    return CompareSelectedValue(value: value, compareType: ConditionCompareType.less);
  }

  factory CompareSelectedValue.greaterEqual(Object value) {
    return CompareSelectedValue(value: value, compareType: ConditionCompareType.greaterEqual);
  }

  factory CompareSelectedValue.lessEqual(Object value) {
    return CompareSelectedValue(value: value, compareType: ConditionCompareType.lessEqual);
  }

  @override
  bool execute() {
    log('Warning: CompareSelectedValue condition is being evaluated without a selected value. This condition will always be false', name: 'CompareSelectedValue');
    return false;
  }
}
