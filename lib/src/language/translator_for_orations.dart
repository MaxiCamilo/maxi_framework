import 'package:maxi_framework/maxi_framework.dart';

abstract interface class TranslatorForOrations {
  Oration translateOration({required Oration oration});
}

class NoOrationTranslator implements TranslatorForOrations {
  const NoOrationTranslator();

  @override
  Oration translateOration({required Oration oration}) {
    return oration;
  }
}






