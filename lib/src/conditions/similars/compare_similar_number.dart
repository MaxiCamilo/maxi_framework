import 'package:maxi_framework/src/conditions/conditionator.dart';

class CompareSimilarNumber implements Conditionator {
  final num number;
  final num similarTo;

  const CompareSimilarNumber({required this.number, required this.similarTo});

  @override
  bool execute() {
    return similarTo.toString().contains(number.toString());
  }
}
