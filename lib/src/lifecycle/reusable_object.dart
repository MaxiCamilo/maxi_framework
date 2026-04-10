import 'dart:async';

import 'package:maxi_framework/maxi_framework.dart';

class ReusableObject<T extends Disposable> with DisposableMixin, AsynchronouslyInitializedMixin, FunctionalityMixin<T> {
  final T value;

  ReusableObject({required this.value});

  @override
  Future<Result<void>> performInitialize() async {
    if (value is AsynchronouslyInitialized) {
      final initResult = await (value as AsynchronouslyInitialized).initialize();
      if (initResult.itsFailure) {
        return initResult.cast();
      }
    } else if (value is Initializable) {
      final initResult = (value as Initializable).initialize();
      if (initResult.itsFailure) {
        return initResult.cast();
      }
    } else if (value is DisposableMixin) {
      (value as DisposableMixin).resurrectObject();
    }

    value.onDispose.whenComplete(() => dispose());

    return voidResult;
  }

  @override
  FutureResult<T> runInternalFuncionality() => initialize().selectFuture((_) => value);
}
