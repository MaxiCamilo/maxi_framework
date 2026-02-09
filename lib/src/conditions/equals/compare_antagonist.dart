import 'package:maxi_framework/src/conditions/conditionator.dart';

/// Negates the result of another conditionator
class CompareAntagonist implements Conditionator {
  final Conditionator conditionator;

  const CompareAntagonist(this.conditionator);

  @override
  bool execute() => !conditionator.execute();
}
