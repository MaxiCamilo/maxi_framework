import 'package:maxi_framework/maxi_framework.dart';
import 'package:meta/meta.dart';

abstract interface class Initializable {
  bool get isInitialized;
  Result<void> initialize();
}

mixin InitializableMixin on DisposableMixin implements Initializable {
  bool _isInitialized = false;
  bool _itsInitializationProcess = false;

  @override
  bool get isInitialized => _isInitialized;

  @protected
  Result<void> performInitialization();

  @override
  Result<void> initialize() {
    resurrectObject();

    if (_isInitialized) {
      return voidResult;
    }

    if (_itsInitializationProcess) {
      throw Exception('[¡¡!!] Circular dependency on object $runtimeType');
    }

    _itsInitializationProcess = true;

    late final Result<void> result;
    try {
      result = performInitialization();
    } finally {
      _itsInitializationProcess = false;
    }

    if (result.itsCorrect) {
      onDispose.whenComplete(() => _isInitialized = false);
      _isInitialized = true;
    }

    return result;
  }
}
