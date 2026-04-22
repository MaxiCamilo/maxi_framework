import 'package:maxi_framework/maxi_framework.dart';
import 'package:meta/meta.dart';

abstract interface class SyncFunctionality<T> {
  Result<T> execute();
}

mixin SyncFunctionalityCache<T> implements SyncFunctionality<T> {
  bool _itsInit = false;
  Result<T>? _lastResult;

  @protected
  Result<T> runInternalFuncionality();

  @override
  Result<T> execute() {
    if (_itsInit && _lastResult != null) {
      return _lastResult!;
    }

    try {
      final result = runInternalFuncionality();
      if (result.itsCorrect) {
        _lastResult = result;
        _itsInit = true;
      }
      return result;
    } catch (ex, st) {
      return ExceptionResult(
        exception: ex,
        stackTrace: st,
        message: FlexibleOration(message: 'An error occurred while executing the functionality %1', textParts: [runtimeType]),
      );
    }
  }

  void reset() {
    _itsInit = false;
    _lastResult = null;
  }
}
