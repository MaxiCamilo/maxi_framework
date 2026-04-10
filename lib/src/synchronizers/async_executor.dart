import 'dart:async';
import 'dart:developer';

import 'package:maxi_framework/maxi_framework.dart';
import 'package:rxdart/transformers.dart';

class AsyncExecutor<T> with DisposableMixin implements AsyncResult<T> {
  static const _errorText = FixedOration(message: 'An internal error occurred while executing a feature');

  final FutureOr<Result<T>> Function() _function;
  final void Function()? _onCancel;
  final Oration _exceptionMessage;
  final void Function(LifeCoordinator)? _onHeartCreated;
  final bool _connectToZone;

  bool _isActive = false;
  bool _heartDispose = false;
  Mutex? _mutex;
  LifeCoordinator? _actualHeart;
  Future? _onHeartDispose;
  MasterChannel<dynamic, dynamic>? _messageChannel;

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

  void connectToHeart() {
    final heart = LifeCoordinator.tryGetZoneHeart;
    if (heart != null) {
      if (heart.itWasDiscarded) {
        _heartDispose = true;
      } else {
        _heartDispose = false;
        _onHeartDispose = heart.onDispose.whenComplete(dispose);
      }
    }
  }

  void sendMessage(dynamic item) {
    if (itWasDiscarded) {
      log('[AsyncExecutor] Trying to send a message to an executor that was already discarded');
      return;
    }

    if (_messageChannel == null || _messageChannel!.itWasDiscarded == true) {
      log('[AsyncExecutor] Trying to send a message, but the sender is not available');
      return;
    }

    _messageChannel!.sendItem(item).logIfFails(errorName: 'AsyncExecutor -> sendMessage');
  }

  Stream<R> messages<R>() {
    if (itWasDiscarded) {
      log('[AsyncExecutor] Trying to listen messages of an executor that was already discarded');
      return Stream.empty();
    }

    if (_messageChannel == null || _messageChannel!.itWasDiscarded == true) {
      _messageChannel = MasterChannel<dynamic, dynamic>();
    }

    return _messageChannel!.getReceiver().content.whereType<R>();
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

    if (_heartDispose) {
      _onHeartDispose?.ignore();
      _isActive = false;
      final cancel = CancelationResult<T>();
      appManager.exceptionChannel.sendItem((cancel, StackTrace.current));
      return cancel;
    }

    if (_messageChannel == null || _messageChannel!.itWasDiscarded == true) {
      _messageChannel = MasterChannel<dynamic, dynamic>();
    }

    final messChannel = _messageChannel!.buildConnector();
    if (messChannel.itsFailure) {
      return messChannel.cast();
    }

    final heart = LifeCoordinator(messChannel.content);
    _actualHeart = heart;
    final whenDispose = onDispose.whenComplete(() => heart.dispose());

    Future? whenRootDispose;

    if (_connectToZone && LifeCoordinator.hasZoneHeart) {
      final parent = LifeCoordinator.zoneHeart;
      whenRootDispose = parent.onDispose.whenComplete(dispose);
    }

    if (_onHeartCreated != null) {
      _onHeartCreated(heart);
    }

    final child = Zone.current.fork(
      zoneValues: {...zoneValues, LifeCoordinator.kZoneHeart: heart, LifeCoordinator.kRootZoneHeart: LifeCoordinator.hasRootZoneHeart ? LifeCoordinator.rootZoneHeart : heart, AsyncResult.kAsyncExecutor: this},
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

    _actualHeart = null;

    whenDispose.ignore();
    whenRootDispose?.ignore();
    heart.dispose();
    _onHeartDispose?.ignore();

    if (_mutex != null && _mutex!.onlyHasOne) {
      _mutex = null;
      _isActive = false;
      dispose();
    }

    return result;
  }

  @override
  void performObjectDiscard() {
    _actualHeart?.dispose();
    _actualHeart = null;

    _messageChannel?.dispose();
    _messageChannel = null;

    if (_isActive && _onCancel != null) {
      try {
        _onCancel();
      } catch (ex) {
        log('[AsyncExecutor] Error to cancel: $ex');
      }
    }
  }
}
