import 'package:maxi_framework/src/conditions/conditionator.dart';

/// Compares multiple conditionators either as a conjunction (all must match) or disjunction (any can match)
class CompareNested implements Conditionator {
  final Iterable<Conditionator> conditionators;
  final bool allMustMatch;

  const CompareNested._({required this.conditionators, required this.allMustMatch});

  factory CompareNested.conjunction(Iterable<Conditionator> conditionators) {
    return CompareNested._(conditionators: conditionators, allMustMatch: true);
  }

  factory CompareNested.disjunction(Iterable<Conditionator> conditionators) {
    return CompareNested._(conditionators: conditionators, allMustMatch: false);
  }

  @override
  bool execute() {
    if (allMustMatch) {
      return conditionators.every((conditionator) => conditionator.execute());
    } else {
      return conditionators.any((conditionator) => conditionator.execute());
    }
  }
}
