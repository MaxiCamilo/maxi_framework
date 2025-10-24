import 'package:maxi_framework/maxi_framework.dart';

abstract class Oration {
  String get tokenID;
  String get message;
  List get textParts;
  bool get translated;
  String get contextText;

  const Oration();

  static Oration searchOration({required List list, required Oration defaultOration}) {
    return list.selectType<Oration>() ?? defaultOration;
  }

  @override
  bool operator ==(Object other) {
    if (other is! Oration) {
      return false;
    }

    if (tokenID != other.tokenID || textParts.length != other.textParts.length || message != other.message) {
      return false;
    }

    for (int i = 0; i < textParts.length; i++) {
      if (textParts[i] != other.textParts[i]) {
        return false;
      }
    }
    return true;
  }

  @override
  int get hashCode =>
      Object.hash(tokenID, message, _getListPart(0), _getListPart(1), _getListPart(2), _getListPart(3), _getListPart(4), _getListPart(5), _getListPart(6), _getListPart(7), _getListPart(8), _getListPart(9));

  Object? _getListPart(int i) => textParts.length <= i ? 0 : textParts[i].hashCode;
}

class FixedOration extends Oration {
  @override
  final String message;

  @override
  final String tokenID;

  @override
  final bool translated;

  @override
  List get textParts => const [];

  @override
  final String contextText;

  const FixedOration({required this.message, this.tokenID = '', this.translated = false, this.contextText = ''});

  factory FixedOration.clone(Oration oration) => FixedOration(message: oration.message, tokenID: oration.tokenID, contextText: oration.contextText, translated: oration.translated);

  @override
  String toString() => message;
}

const emptyOration = FixedOration(message: '');

class FlexibleOration extends Oration {
  @override
  final String tokenID;
  @override
  final String message;
  @override
  final List textParts;
  @override
  final bool translated;
  @override
  final String contextText;

  bool get isFixed => textParts.isEmpty;
  bool get isNotEmpty => message.isNotEmpty;
  bool get isEmpty => message.isEmpty;

  const FlexibleOration({required this.message, required this.textParts, this.tokenID = '', this.translated = false, this.contextText = ''});

  factory FlexibleOration.clone(Oration oration) => FlexibleOration(message: oration.message, tokenID: oration.tokenID, contextText: oration.contextText, translated: oration.translated, textParts: oration.textParts);

  @override
  String toString() {
    if (isFixed) {
      return message;
    }

    String formated = message;

    for (int i = 0; i < textParts.length; i++) {
      formated = formated.replaceAll('%${i + 1}', textParts[i].toString());
    }

    return formated;
  }
}
