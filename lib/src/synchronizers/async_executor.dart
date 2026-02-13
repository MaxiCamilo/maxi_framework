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

  final _currentListeners = <Function>[];

  bool _isActive = false;
  bool _heartDispose = false;
  Mutex? _mutex;
  LifeCoordinator? _actualHeart;
  Future? _onHeartDispose;

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

  void addListener<I>(Function(I) listener) {
    _currentListeners.add(listener);
  }

  Stream<I> createListenerStream<I>() {
    if (itWasDiscarded) {
      throw NegativeResult.controller(
        code: ErrorCode.implementationFailure,
        message: const FixedOration(message: 'An attempt was made to create a listener stream for an AsyncExecutor that was already discarded'),
      );
    }
    final controller = StreamController<I>();
    addListener<I>((item) => controller.add(item));
    onDispose.whenComplete(() => controller.close());
    return controller.stream;
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
      return CancelationResult<T>();
    }

    if (_heartDispose) {
      _onHeartDispose?.ignore();
      _isActive = false;
      return CancelationResult<T>();
    }

    final heart = LifeCoordinator();
    _actualHeart = heart;
    final whenDispose = onDispose.whenComplete(() => heart.dispose());

    Future? whenRootDispose;
    if (_connectToZone && LifeCoordinator.hasZoneHeart) {
      whenRootDispose = LifeCoordinator.zoneHeart.onDispose.whenComplete(dispose);
    }

    if (_onHeartCreated != null) {
      _onHeartCreated(heart);
    }

    final listenersInArea = Zone.current[InteractiveSystem.kInteractiveSymbolName];
    final listeners = <Function>[];

    if (listenersInArea is List) {
      listeners.addAll(listenersInArea.whereType<Function>());
    }

    _currentListeners.addAll(listeners);
    _currentListeners.clear();

    final child = Zone.current.fork(
      zoneValues: {
        ...zoneValues,
        LifeCoordinator.kZoneHeart: heart,
        LifeCoordinator.kRootZoneHeart: LifeCoordinator.hasRootZoneHeart ? LifeCoordinator.rootZoneHeart : heart,
        AsyncResult.kAsyncExecutor: this,
        InteractiveSystem.kInteractiveSymbolName: listeners,
      },
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

    if (_isActive && _onCancel != null) {
      try {
        _onCancel();
      } catch (ex) {
        log('[AsyncExecutor] Error to cancel: $ex');
      }
    }
  }
}
