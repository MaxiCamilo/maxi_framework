import 'dart:async';
import 'dart:developer';

import 'package:maxi_framework/maxi_framework.dart';

class AsyncExecutor<T> with DisposableMixin implements AsyncResult<T> {
  static const _errorText = FixedOration(message: 'An internal error occurred while executing a feature');

  final FutureOr<Result<T>> Function() _function;
  final void Function()? _onCancel;
  final Oration _exceptionMessage;
  final void Function(LifeCoordinator)? _onHeartCreated;
  final bool _connectToZone;

  bool _isActive = false;
  Mutex? _mutex;
  LifeCoordinator? _actualHeart;
  Future? _onHeartDispose;
  MasterChannel<InteractiveSystemValue, InteractiveSystemValue>? _valueChannel;

  @override
  bool get isActive => _isActive;

  AsyncExecutor({required FutureOr<Result<T>> Function() function, void Function()? onCancel, Oration? exceptionMessage, void Function(LifeCoordinator)? onHeartCreated, bool connectToZone = true})
    : _function = function,
      _onCancel = onCancel,
      _onHeartCreated = onHeartCreated,
      _exceptionMessage = exceptionMessage ?? _errorText,
      _connectToZone = connectToZone;

  factory AsyncExecutor.function({required FutureOr<T> Function() function, void Function()? onCancel, Oration? exceptionMessage, void Function(LifeCoordinator)? onHeartCreated, bool connectToZone = true}) {
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
    _mutex ??= Mutex();

    return _mutex!.execute(() => _waitResultSync(zoneValues: zoneValues));
  }

  Future<Result<T>> _waitResultSync({required Map<Object?, Object?> zoneValues}) async {
    _isActive = true;
    if (itWasDiscarded) {
      _isActive = false;
      final cancel = CancelationResult<T>();
      appManager.exceptionChannel.sendItem((cancel, StackTrace.current));
      return cancel;
    }

    if (_connectToZone && LifeCoordinator.isZoneHeartCanceled) {
      _isActive = false;
      final cancel = CancelationResult<T>();
      appManager.exceptionChannel.sendItem((cancel, StackTrace.current));
      return cancel;
    }

    if (_connectToZone && LifeCoordinator.hasZoneHeart) {
      final parent = LifeCoordinator.zoneHeart;
      parent.onDispose.whenComplete(dispose);
    }

    final heart = LifeCoordinator();
    _actualHeart = heart;
    final whenDispose = onDispose.whenComplete(() => heart.dispose());

    bool channelWasCreated = false;
    if (_valueChannel == null || _valueChannel!.itWasDiscarded) {
      if (_connectToZone) {
        final mainResult = InteractiveSystem.obtainChannel();
        if (mainResult.itsFailure) {
          _valueChannel = MasterChannel<InteractiveSystemValue, InteractiveSystemValue>();
          channelWasCreated = true;
        } else {
          _valueChannel = mainResult.content;
        }
      } else {
        _valueChannel = MasterChannel<InteractiveSystemValue, InteractiveSystemValue>();
        channelWasCreated = true;
      }
    }

    if (_onHeartCreated != null) {
      _onHeartCreated(heart);
    }

    final child = Zone.current.fork(
      zoneValues: {
        ...zoneValues,
        LifeCoordinator.kZoneHeart: heart,
        LifeCoordinator.kRootZoneHeart: LifeCoordinator.hasRootZoneHeart ? LifeCoordinator.rootZoneHeart : heart,
        AsyncResult.kAsyncExecutor: this,
        InteractiveSystem.kInteractiveSymbolName: _valueChannel!,
      },
    );
    final futureResult = child.run<Future<Result<T>>>(() async {
      try {
        return await _function();
      } catch (ex, st) {
        appManager.exceptionChannel.sendItem((ex, st));
        log('Exception detected!: $ex');
        log('------------------------------------------------------------------');
        log(st.toString());
        log('------------------------------------------------------------------');
        return ExceptionResult(exception: ex, stackTrace: st, message: _exceptionMessage);
      }
    });

    final result = await Future<Result<T>>.value(futureResult);
    await Future.delayed(Duration.zero);

    _actualHeart = null;

    whenDispose.ignore();
    heart.dispose();

    _onHeartDispose?.ignore();

    if (channelWasCreated) {
      _valueChannel?.dispose();
      _valueChannel = null;
    }

    if (_mutex != null && _mutex!.onlyHasOne) {
      _mutex = null;
      _isActive = false;
      dispose();
    }

    return result;
  }

  void sendMessage({dynamic value, dynamic payload}) {
    if (_valueChannel != null && !_valueChannel!.itWasDiscarded) {
      _valueChannel!.sendItem(InteractiveSystemValue(value: value, payload: payload));
    }
  }

  @override
  void performObjectDiscard() {
    _actualHeart?.dispose();
    _actualHeart = null;

    _mutex?.dispose();
    _mutex = null;

    if (_isActive && _onCancel != null) {
      try {
        _onCancel();
      } catch (ex) {
        log('[AsyncExecutor] Error to cancel: $ex');
      }
    }
  }
}
