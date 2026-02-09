import 'package:maxi_framework/src/conditions/conditionator.dart';

class CompareSimilarText implements Conditionator {
  final String text;
  final String similarTo;
  final bool differentiateUppercaseLetters;

  const CompareSimilarText({required this.text, required this.similarTo, required this.differentiateUppercaseLetters});

  @override
  bool execute() {
    if (differentiateUppercaseLetters) {
      return text == similarTo;
    } else {
      return text.toLowerCase() == similarTo.toLowerCase();
    }
  }
}
