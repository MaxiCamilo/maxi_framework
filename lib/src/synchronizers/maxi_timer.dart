import 'dart:async';

import 'package:maxi_framework/maxi_framework.dart';

class MaxiTimer<T> with DisposableMixin implements Timer {
  bool _isActive = false;
  bool _hasBeenConfigured = false;
  bool _hasPause = false;
  Timer? _originalTimer;
  final Stopwatch _stopwatch = Stopwatch();
  late Duration _duration;
  late T _payload;

  Completer<T>? _timeoutCompleter;
  Completer<void>? _cancelCompleter;
  Completer<bool>? _completerExecution;

  @override
  void cancel() => dispose();

  @override
  bool get isActive => _isActive;
  @override
  int get tick => _originalTimer?.tick ?? 0;

  Duration get elapsed {
    if (!_hasBeenConfigured) {
      throw StateError('The timer has not been configured yet. Please call startOrReset first.');
    }
    return _stopwatch.elapsed;
  }

  Duration get remaining {
    if (!_hasBeenConfigured) {
      throw StateError('The timer has not been configured yet. Please call startOrReset first.');
    }
    final remaining = _duration - _stopwatch.elapsed;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  Future<T> get onTimeout {
    _timeoutCompleter ??= Completer<T>();
    return _timeoutCompleter!.future;
  }

  Future<void> get onCancel {
    _cancelCompleter ??= Completer<void>();
    return _cancelCompleter!.future;
  }

  Future<bool> get onFinishOrInterrupt {
    _completerExecution ??= Completer<bool>();
    return _completerExecution!.future;
  }

  Future<bool> startOrReset({required Duration duration, required T payload, void Function(T)? onFinish, void Function(T)? onInterrupt}) async {
    if (_isActive) {
      cancel();
    }

    _duration = duration;
    _payload = payload;

    _hasBeenConfigured = true;
    _hasPause = false;

    final completer = Completer<bool>();

    performResurrection();

    late final Future<void> onCancel;
    late final Future<T> onTimeout;

    onCancel = this.onCancel.whenComplete(() {
      if (completer.isCompleted) return;
      completer.complete(false);
      onTimeout.ignore();
      if (onInterrupt != null) {
        onInterrupt(_payload);
      }
    });

    onTimeout = this.onTimeout.whenComplete(() {
      if (completer.isCompleted) return;
      completer.complete(true);
      onCancel.ignore();
      if (onFinish != null) {
        onFinish(_payload);
      }
    });

    final isTimeout = await completer.future;

    if (_completerExecution != null && !_completerExecution!.isCompleted) {
      _completerExecution!.complete(isTimeout);
    }

    return isTimeout;
  }

  void reset() {
    if (!_hasBeenConfigured) {
      throw StateError('The timer has not been configured yet. Please call startOrReset first.');
    }
    startOrReset(duration: _duration, payload: _payload);
  }

  bool pause() {
    if (!_isActive) {
      return false;
    }
    _originalTimer?.cancel();
    _originalTimer = null;
    _isActive = false;
    _hasPause = true;
    _stopwatch.stop();
    return true;
  }

  bool resume() {
    if (!_hasPause) {
      return false;
    }
    _hasPause = false;
    _isActive = true;
    _originalTimer = Timer(remaining, _onOriginalTimerComplete);
    _stopwatch.start();
    return true;
  }

  Future<T?> waitFinish({void Function(T)? onInterrupt}) async {
    if (!_isActive) {
      return null;
    }

    final completer = Completer<T?>();

    late final Future<void> onCancel;
    late final Future<T> onTimeout;

    onCancel = this.onCancel.whenComplete(() {
      if (completer.isCompleted) return;
      completer.complete(null);
      onTimeout.ignore();
      if (onInterrupt != null) {
        onInterrupt(_payload);
      }
    });

    onTimeout = this.onTimeout.whenComplete(() {
      if (completer.isCompleted) return;
      completer.complete(_payload);
      onCancel.ignore();
    });

    return completer.future;
  }

  @override
  void performResurrection() {
    super.performResurrection();
    _isActive = true;
    _stopwatch
      ..reset()
      ..start();
    _originalTimer = Timer(_duration, _onOriginalTimerComplete);
  }

  void _onOriginalTimerComplete() {
    if (_timeoutCompleter != null && !_timeoutCompleter!.isCompleted) {
      _timeoutCompleter!.complete(_payload);
      _timeoutCompleter = null;
    }
    dispose();
  }

  @override
  void performObjectDiscard() {
    _originalTimer?.cancel();
    _originalTimer = null;
    _isActive = false;
    _hasPause = false;
    _stopwatch
      ..stop()
      ..reset();
    if (_cancelCompleter != null && !_cancelCompleter!.isCompleted) {
      _cancelCompleter!.complete();
    }
    if (_timeoutCompleter != null && !_timeoutCompleter!.isCompleted) {
      _timeoutCompleter!.completeError(
        NegativeResult.controller(
          code: ErrorCode.functionalityCancelled,
          message: FixedOration(message: 'The timer was cancelled before completion'),
        ),
      );
    }

    if (_completerExecution != null && !_completerExecution!.isCompleted) {
      _completerExecution!.complete(false);
    }

    _cancelCompleter = null;
    _timeoutCompleter = null;
    _completerExecution = null;
  }
}
