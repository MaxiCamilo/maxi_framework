import 'package:maxi_framework/maxi_framework.dart';

TranslatorForOrations _intance = const NoOrationTranslator();

TranslatorForOrations get appTranslator => _intance;

FutureResult<void> changeAppTranslator(TranslatorForOrations translator) async {
  if (translator is Initializable) {
    final initResult = (translator as Initializable).initialize();
    if (!initResult.itsCorrect) {
      return initResult.asResultValue();
    }
  }

  if (translator is AsynchronouslyInitialized) {
    final initResult = await (translator as AsynchronouslyInitialized).initialize();
    if (!initResult.itsCorrect) {
      return initResult.asResultValue();
    }
  }

  if (_intance is Disposable) {
    (_intance as Disposable).dispose();
  }

  _intance = translator;

  return voidResult;
}
