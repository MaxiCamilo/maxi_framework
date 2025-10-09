import 'dart:async';
import 'dart:developer';

import 'package:maxi_framework/maxi_framework.dart';

class AsyncExecutor<T> with DisposableMixin implements AsyncResult<T> {
  static const _errorText = FixedOration(message: 'An internal error occurred while executing a feature');

  final FutureOr<Result<T>> Function() _function;
  final void Function()? _onCancel;
  final Oration _exceptionMessage;
  final void Function(ParentController)? _onHeartCreated;
  final bool _connectToZone;

  bool _isActive = false;
  Semaphore? _semaphore;
  ParentController? _actualHeart;

  @override
  bool get isActive => _isActive;

  AsyncExecutor({required FutureOr<Result<T>> Function() function, void Function()? onCancel, Oration? exceptionMessage, void Function(ParentController)? onHeartCreated, bool connectToZone = true})
    : _function = function,
      _onCancel = onCancel,
      _onHeartCreated = onHeartCreated,
      _exceptionMessage = exceptionMessage ?? _errorText,
      _connectToZone = connectToZone;

  factory AsyncExecutor.function({required FutureOr<T> Function() function, void Function()? onCancel, Oration? exceptionMessage, void Function(ParentController)? onHeartCreated, bool connectToZone = true}) {
    return AsyncExecutor(
      function: () async => ResultValue(content: await function()),
      onCancel: onCancel,
      onHeartCreated: onHeartCreated,
      exceptionMessage: exceptionMessage,
      connectToZone: connectToZone,
    );
  }

  @override
  Future<Result<T>> waitResult({Map<Object?, Object?> zoneValues = const {}}) {
    resurrectObject();
    _semaphore ??= Semaphore();

    return _semaphore!.execute(() => _waitResultSync(zoneValues: zoneValues));
  }

  Future<Result<T>> _waitResultSync({required Map<Object?, Object?> zoneValues}) async {
    _isActive = true;
    if (itWasDiscarded) {
      _isActive = false;
      return CancelationResult<T>(cancelationStackTrace: StackTrace.current);
    }

    final heart = ParentController();
    _actualHeart = heart;
    final whenDispose = onDispose.whenComplete(() => heart.dispose());

    Future? whenRootDispose;
    if (_connectToZone && ParentController.hasZoneHeart) {
      whenRootDispose = ParentController.zoneHeart.onDispose.whenComplete(dispose);
    }

    if (_onHeartCreated != null) {
      _onHeartCreated(heart);
    }

    final child = Zone.current.fork(
      zoneValues: {ParentController.kZoneHeart: heart, ParentController.kRootZoneHeart: ParentController.hasRootZoneHeart ? ParentController.rootZoneHeart : heart, AsyncResult.kAsyncExecutor: this, ...zoneValues},
    );
    final futureResult = child.run<Future<Result<T>>>(() async {
      try {
        return await _function();
      } catch (ex, st) {
        log('Exception detected!: $ex');
        log('------------------------------------------------------------------');
        log(st.toString());
        log('------------------------------------------------------------------');
        return ExceptionResult(exception: ex, stackTrace: st, message: _exceptionMessage);
      }
    });

    final result = await Future<Result<T>>.value(futureResult);

    _actualHeart = null;
    whenDispose.ignore();
    whenRootDispose?.ignore();
    heart.dispose();

    if (_semaphore != null && _semaphore!.onlyHasOne) {
      _semaphore = null;
      _isActive = false;
      dispose();
    }

    return result;
  }

  @override
  void performObjectDiscard() {
    _actualHeart?.dispose();
    _actualHeart = null;

    if (_isActive && _onCancel != null) {
      try {
        _onCancel();
      } catch (ex) {
        log('[AsyncExecutor] Error to cancel: $ex');
      }
    }
  }
}
