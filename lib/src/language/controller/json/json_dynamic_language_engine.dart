import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_framework/src/language/controller/json/logic/load_json_prefix.dart';

class JsonDynamicLanguageEngine with DisposableMixin, AsynchronouslyInitializedMixin, LifecycleHub implements TranslatorForOrations {
  final List<FolderReference> directories;
  final String initPrefix;
  final int maxFileSize;

  String _prefix = '';
  DynamicLanguageEngine? _realEngine;

  @override
  String get languagePrefix => _realEngine?.languagePrefix ?? _prefix;

  @override
  int get uniqueID => _realEngine?.uniqueID ?? (_prefix.isEmpty ? 0 : _prefix.hashCode);

  JsonDynamicLanguageEngine({required this.directories, required this.initPrefix, required this.maxFileSize});

  factory JsonDynamicLanguageEngine._internalClone({required JsonDynamicLanguageEngine other, required DynamicLanguageEngine main}) {
    final engine = JsonDynamicLanguageEngine(directories: other.directories, initPrefix: other.initPrefix, maxFileSize: other.maxFileSize);
    engine._prefix = other._prefix;
    engine._realEngine = main;
    return engine;
  }

  @override
  Future<Result<void>> performInitialize() async {
    if (_realEngine != null) {
      return _realEngine!.initialize();
    }

    if (_prefix.isEmpty) {
      _prefix = initPrefix;
    }

    _realEngine = lifecycleScope.joinDisposableObject(
      DynamicLanguageEngine(
        languagePrefix: _prefix,
        loaders: [LoadJsonPrefix(directories: directories, prefix: _prefix, maxFileSize: maxFileSize)],
      ),
    );

    final result = await _realEngine!.initialize();
    if (!result.itsCorrect) {
      return result;
    }

    return voidResult;
  }

  @override
  void performInitializedObjectDiscard() {
    super.performInitializedObjectDiscard();
    _realEngine = null;
  }

  @override
  Oration translateOration({required Oration oration}) {
    if (isInitialized) {
      return _realEngine!.translateOration(oration: oration);
    }

    initialize().logIfFails(errorName: 'Failed to initialize the language engine');

    return oration;
  }

  @override
  FutureResult<TranslatorForOrations> clone() async {
    final initResult = await initialize();
    if (!initResult.itsCorrect) {
      return initResult.asResultValue();
    }

    final realEngineCloneResult = await _realEngine!.clone();
    if (!realEngineCloneResult.itsCorrect) {
      return realEngineCloneResult.asResultValue();
    }

    return JsonDynamicLanguageEngine._internalClone(other: this, main: realEngineCloneResult.content as DynamicLanguageEngine).asResultValue();
  }
}
