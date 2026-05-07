import 'dart:convert';

class ReferenceOration {
  String tokenID = '';
  String message = '';
  String translation = '';

  ReferenceOration();

  ReferenceOration.fromMap(Map<String, dynamic> map) {
    tokenID = map['tokenID'] ?? '';
    message = map['message'] ?? '';
    translation = map['translation'] ?? '';
  }

  Map<String, dynamic> toMap() {
    return {'tokenID': tokenID, 'message': message, 'translation': translation, '\$type': 'TranslationText.v1'};
  }

  String toJson() => json.encode(toMap());
}
