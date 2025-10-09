import 'package:maxi_framework/maxi_framework.dart';
import 'package:meta/meta.dart';

abstract interface class Initializable {
  bool get isInitialized;
  Result<void> initialize();
}

mixin InitializableMixin on DisposableMixin implements Initializable {
  bool _isInitialized = false;

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

    final result = performInitialization();

    if (result.itsCorrect) {
      onDispose.whenComplete(() => _isInitialized = false);
      _isInitialized = true;
    }

    return result;
  }
}
