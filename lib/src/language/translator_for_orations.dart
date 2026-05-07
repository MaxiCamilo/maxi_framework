import 'package:maxi_framework/maxi_framework.dart';

abstract interface class TranslatorForOrations {
  Oration translateOration({required Oration oration});

  FutureResult<TranslatorForOrations> clone();
}

class NoOrationTranslator implements TranslatorForOrations {
  const NoOrationTranslator();

  @override
  Oration translateOration({required Oration oration}) {
    return oration;
  }

  @override
  FutureResult<TranslatorForOrations> clone() async => const NoOrationTranslator().asResultValue();
}
