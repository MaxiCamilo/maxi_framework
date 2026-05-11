import 'dart:async';
import 'dart:developer';
import 'dart:math' show Random;

import 'package:maxi_framework/maxi_framework.dart';

class DynamicLanguageEngine with DisposableMixin, AsynchronouslyInitializedMixin, LifecycleHub implements TranslatorForOrations {
  @override
  final String languagePrefix;

  final List<Functionality<List<ReferenceOration>>> loaders;

  final _orations = <ReferenceOration>[];
  final _translationKeyCache = <String, String>{};
  StreamController<Oration>? _onUnknownTextTransaction;
  int? _uniqueID;

  Stream<Oration> get onUnknownText async* {
    _onUnknownTextTransaction = lifecycleScope.joinStreamController(StreamController<Oration>.broadcast(), onClose: (_) => _onUnknownTextTransaction = null);

    final initResult = await initialize();
    if (initResult.itsCorrect) {
      yield* Stream.error(initResult);
      return;
    }

    yield* _onUnknownTextTransaction!.stream;
  }

  @override
  int get uniqueID {
    if (_uniqueID != null) {
      return _uniqueID!;
    }

    if (isInitialized) {
      _uniqueID = Object.hashAll([languagePrefix, ..._orations.map((o) => Object.hash(o.tokenID, o.translation))]);
      return _uniqueID!;
    } else {
      return (Random().nextInt(9999999999999)) * -1;
    }
  }

  DynamicLanguageEngine({required this.languagePrefix, required this.loaders});

  factory DynamicLanguageEngine._internalClone({required DynamicLanguageEngine other}) {
    final engine = DynamicLanguageEngine(languagePrefix: other.languagePrefix, loaders: other.loaders);
    engine._orations.addAll(other._orations);
    engine._translationKeyCache.addAll(other._translationKeyCache);
    return engine;
  }

  @override
  FutureResult<void> performInitialize() async {
    if (_orations.isNotEmpty && _translationKeyCache.isNotEmpty) {
      return voidResult;
    }

    _orations.clear();
    _translationKeyCache.clear();

    for (final loader in loaders) {
      final result = await loader.execute();
      if (result.itsCorrect) {
        _orations.addAll(result.content);
      } else {
        return result.asResultValue();
      }
    }

    for (final item in _orations) {
      if (item.tokenID.isEmpty) {
        final tokenID = Oration.buildAutomaticTokenID(typeKey: item is FlexibleOration ? 'f' : 't', message: item.message);
        _translationKeyCache[tokenID] = item.translation;
      } else {
        _translationKeyCache[item.tokenID] = item.translation;
      }
    }

    return voidResult;
  }

  @override
  void performInitializedObjectDiscard() {
    super.performInitializedObjectDiscard();
    _orations.clear();
    _translationKeyCache.clear();
  }

  @override
  Oration translateOration({required Oration oration}) {
    if (!isInitialized) {
      if (!isInitializing) {
        initialize().logIfFails(errorName: 'Failed to initialize the language engine');
      }
      return oration;
    }

    final tokenID = oration.tokenID;
    final translation = _translationKeyCache[tokenID];
    if (translation == null) {
      log('Unknown translation for tokenID: $tokenID, message: ${oration.message}', name: 'DynamicLanguageEngine');

      _translationKeyCache[tokenID] = oration.message;
      _onUnknownTextTransaction?.add(oration);

      return oration;
    }

    if (oration is FlexibleOration) {
      final convert = FlexibleOration(message: translation, textParts: oration.textParts, tokenID: tokenID, contextText: oration.contextText, translated: true);

      return FixedOration(message: convert.toString(), tokenID: tokenID, contextText: oration.contextText, translated: true);
    } else {
      return FixedOration(message: translation, tokenID: tokenID, contextText: oration.contextText, translated: true);
    }
  }

  @override
  FutureResult<TranslatorForOrations> clone() async {
    final initResult = await initialize();
    if (!initResult.itsCorrect) {
      return initResult.asResultValue();
    }

    return DynamicLanguageEngine._internalClone(other: this).asResultValue();
  }
}
