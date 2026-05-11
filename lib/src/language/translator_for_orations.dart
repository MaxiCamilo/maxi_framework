import 'package:maxi_framework/maxi_framework.dart';

abstract interface class TranslatorForOrations {
  int get uniqueID;

  String get languagePrefix;

  Oration translateOration({required Oration oration});

  FutureResult<TranslatorForOrations> clone();
}

class NoOrationTranslator implements TranslatorForOrations {
  const NoOrationTranslator();

  @override
  int get uniqueID => 0;

  @override
  Oration translateOration({required Oration oration}) {
    return oration;
  }

  @override
  String get languagePrefix => 'en';

  @override
  FutureResult<TranslatorForOrations> clone() async => const NoOrationTranslator().asResultValue();
}
