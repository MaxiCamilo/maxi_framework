import 'package:maxi_framework/maxi_framework.dart';

class CacheOration extends Oration {
  final TranslatorForOrations translator;
  late final String formated;
  late final int hashCodeCache;

  @override
  late final String tokenID;
  @override
  late final String contextText;

  CacheOration({required this.translator, required Oration originalOration}) {
    tokenID = originalOration.tokenID;
    formated = translator.translateOration(oration: originalOration).toString();
    hashCodeCache = Object.hash('mx.Oration.cache', translator, formated, tokenID);
  }

  @override
  String get message => formated;

  @override
  List<dynamic> get textParts => const [];

  @override
  bool get translated => true;

  @override
  String toString() => formated;

  @override
  int get hashCode => hashCodeCache;

  @override
  bool operator ==(Object other) {
    return other is CacheOration && other.hashCode == hashCode;
  }

  static CacheOration parse({required TranslatorForOrations translator, required Oration oration}) {
    if (oration is CacheOration && oration.translator == translator) {
      return oration;
    } else {
      return CacheOration(
        translator: translator,
        originalOration: translator.translateOration(oration: oration),
      );
    }
  }

  static CacheOration parseInstance({required TranslatorForOrations translator, required CacheOration? instance, required Oration oration}) {
    if (instance == null) {
      return parse(translator: translator, oration: oration);
    }
    if (instance.hashCode == oration.hashCode) {
      return instance;
    } else {
      return CacheOration(
        translator: translator,
        originalOration: translator.translateOration(oration: oration),
      );
    }
  }
}
