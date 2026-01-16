import 'dart:async';

import 'package:maxi_framework/maxi_framework.dart';


class MaxiTimer<T> with DisposableMixin implements Timer {
  bool _isActive = false;
  Timer? _originalTimer;
  late Duration _duration;
  late T _payload;

  Completer<T>? _completer;
  Completer<void>? _cancelCompleter;

  @override
  void cancel() => dispose();

  @override
  bool get isActive => _isActive;
  @override
  int get tick => _originalTimer?.tick ?? 0;

  Future<T> get onComplete {
    _completer ??= Completer<T>();
    return _completer!.future;
  }

  Future<void> get onCancel {
    _cancelCompleter ??= Completer<void>();
    return _cancelCompleter!.future;
  }

  Future<bool> startOrReset({required Duration duration, required T payload, void Function(T)? onFinish, void Function(T)? onInterrupt}) {
    if (_isActive) {
      cancel();
    }

    _duration = duration;
    _payload = payload;

    final completer = Completer<bool>();

    performResurrection();

    late final Future<void> onCancel;
    late final Future<T> onComplete;

    onCancel = this.onCancel.whenComplete(() {
      if (completer.isCompleted) return;
      completer.complete(false);
      onComplete.ignore();
      if (onInterrupt != null) {
        onInterrupt(_payload);
      }
    });

    onComplete = this.onComplete.whenComplete(() {
      if (completer.isCompleted) return;
      completer.complete(true);
      onCancel.ignore();
      if (onFinish != null) {
        onFinish(_payload);
      }
    });

    return completer.future;
  }

  Future<T?> waithFinish({void Function(T)? onInterrupt}) async {
    if (!_isActive) {
      return null;
    }

    final completer = Completer<T?>();

    late final Future<void> onCancel;
    late final Future<T> onComplete;

    onCancel = this.onCancel.whenComplete(() {
      if (completer.isCompleted) return;
      completer.complete(null);
      onComplete.ignore();
      if (onInterrupt != null) {
        onInterrupt(_payload);
      }
    });

    onComplete = this.onComplete.whenComplete(() {
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
    _originalTimer = Timer(_duration, _onOriginalTimerComplete);
  }

  void _onOriginalTimerComplete() {
    if (_completer != null && !_completer!.isCompleted) {
      _completer!.complete(_payload);
      _completer = null;
    }
    performObjectDiscard();
  }

  @override
  void performObjectDiscard() {
    _originalTimer?.cancel();
    _originalTimer = null;
    _isActive = false;
    if (_cancelCompleter != null && !_cancelCompleter!.isCompleted) {
      _cancelCompleter!.complete();
    }
    if (_completer != null && !_completer!.isCompleted) {
      _completer!.completeError(
        NegativeResult.controller(
          code: ErrorCode.functionalityCancelled,
          message: FixedOration(message: 'The timer was cancelled before completion'),
        ),
      );
    }

    _cancelCompleter = null;
    _completer = null;
  }
}
