import 'dart:async';

import 'package:maxi_framework/maxi_framework.dart';

class TicketReservedValue<T extends Object> with DisposableMixin, LifecycleHub, InitializableMixin implements ValueReserver<T> {
  final ValueReserver<T> _origin;
  final Disposable _scope;

  Completer<void>? _waiterRelease;
  T? _reservedValue;

  TicketReservedValue({required ValueReserver<T> origin, required Disposable scope}) : _origin = origin, _scope = scope;

  @override
  Result<void> performInitialization() {
    if (_scope.itWasDiscarded || _origin.itWasDiscarded) {
      return CancelationResult();
    }

    lifecycleScope.createDependency(_origin);
    lifecycleScope.createDependency(_scope);
    return voidResult;
  }

  @override
  FutureResult<R> invoke<R>({required FutureOr<Result<R>> Function(T) function, Duration? timeout}) async {
    final initResult = initialize();
    if (initResult.itsFailure) {
      return initResult.cast();
    }

    return _origin.invoke(function: function, timeout: timeout);
  }

  FutureResult<T> reserveValue({Duration? timeout}) async {
    final initResult = initialize();
    if (initResult.itsFailure) {
      return initResult.cast();
    }

    if (_reservedValue != null) {
      return ResultValue(content: _reservedValue as T);
    }

    final reserveResult = await invoke(
      function: (value) => ResultValue(content: value),
      timeout: timeout,
    );
    if (reserveResult.itsFailure) {
      return reserveResult.cast();
    }

    _reservedValue = reserveResult.content;

    _waiterRelease = Completer();
    return reserveResult;
  }

  @override
  void performObjectDiscard() {
    if (_waiterRelease != null) {
      _waiterRelease!.complete();
      _waiterRelease = null;
      _reservedValue = null;
    }
  }
}

class ValueObtainer<T extends Object> {
  final ValueReserver<T> _original;

  ValueObtainer(this._original);

  TicketReservedValue<T> claimValueReserver({required Disposable scope}) {
    return TicketReservedValue(origin: _original, scope: scope);
  }

  FutureResult<T> claimValue({required Disposable scope, Duration? timeout}) {
    final ticket = claimValueReserver(scope: scope);
    return ticket.reserveValue(timeout: timeout);
  }
}
