import 'package:maxi_framework/maxi_framework.dart';
import 'package:meta/meta.dart';

mixin LifecycleHub on Disposable {
  bool get canBeReused => false;

  LifecycleScope? _lifecycleScope;

  @nonVirtual
  LifecycleScope get lifecycleScope {
    if (_lifecycleScope == null) {
      if (itWasDiscarded && !canBeReused) {
        throw NegativeResult.controller(
          code: ErrorCode.implementationFailure,
          message: const FixedOration(message: 'This object was discarded and cannot be reused, so it is not possible to access its lifecycle scope'),
        );
      }
      _lifecycleScope = LifecycleScope();
      onDispose.whenComplete(() {
        _lifecycleScope?.dispose();
        _lifecycleScope = null;
      });
    }
    return _lifecycleScope!;
  }
}
