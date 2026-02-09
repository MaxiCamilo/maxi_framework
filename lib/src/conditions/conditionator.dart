///
///Defines what type of logical comparison a condition will perform
enum ConditionCompareType { equal, notEqual, greater, less, greaterEqual, lessEqual }

///Signature for objects that perform a logical comparison, such as comparing two values or evaluating a condition. The execute() function returns a boolean indicating whether the context meets the comparator's goal.
abstract interface class Conditionator {
  /// Executes the logical comparison defined by the comparator, returning true if the context meets the comparator's goal, or false otherwise
  bool execute();
}
