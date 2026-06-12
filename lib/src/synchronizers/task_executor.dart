import 'dart:async';

import 'package:maxi_framework/maxi_framework.dart';

enum TaskExecutorStatus { inactive, active, completed, failed }

extension TaskExecutorToFunctionality<T> on Functionality<T> {
  TaskExecutor<T> toTaskExecutor() => TaskExecutor<T>(functionality: this);
}

class TaskExecutor<T> with DisposableMixin implements Channel {
  final Functionality<T> functionality;

  TaskExecutorStatus _status = TaskExecutorStatus.inactive;
  AsyncExecutor<T>? _executor;

  Result<T>? _result;
  Completer<Result<T>>? _completer;
  Channel? _interactiveChannel;
  TinyEventManager<TaskExecutor<T>>? _onTaskStart;
  MaxiTimer? _autoCancelWaitingTimer;
  MaxiTimer? _timeLimitActivity;

  TinyEvent<TaskExecutor<T>> get onTaskStart {
    _onTaskStart ??= TinyEventManager<TaskExecutor<T>>();
    return _onTaskStart!.createEvent(temporal: true);
  }

  TaskExecutor({required this.functionality});

  void closeWhenWaitingExecution({required Duration duration}) {
    if (_status == TaskExecutorStatus.active) {
      return;
    }

    _autoCancelWaitingTimer ??= MaxiTimer();
    _autoCancelWaitingTimer!.startOrReset(duration: duration, payload: null, onFinish: (_) => dispose());
  }

  void defineLimitTime(Duration duration) {
    if (duration == Duration.zero) {
      _timeLimitActivity?.dispose();
      _timeLimitActivity = null;
      return;
    }

    _timeLimitActivity ??= MaxiTimer();
    _timeLimitActivity!.startOrReset(duration: duration, payload: null);
  }

  Result<T> get lastResult {
    return switch (_status) {
      TaskExecutorStatus.completed => _result!,
      TaskExecutorStatus.failed => _result!,
      TaskExecutorStatus.inactive => NegativeResult.controller(
        code: ErrorCode.invalidFunctionality,
        message: const FixedOration(message: 'The task has not started yet'),
      ),
      TaskExecutorStatus.active => NegativeResult.controller(
        code: ErrorCode.invalidFunctionality,
        message: const FixedOration(message: 'The task is still running'),
      ),
    };
  }

  FutureResult<T> _executeFunctionality() async {
    final newInteractiveChannelResult = InteractiveSystem.forkChannel();
    if (newInteractiveChannelResult.itsCorrect) {
      _interactiveChannel = newInteractiveChannelResult.content;
    }

    return await functionality.execute();
  }

  void run({Map<Object?, Object?> zoneValues = const {}}) {
    if (_status == TaskExecutorStatus.active || _status == TaskExecutorStatus.completed || _status == TaskExecutorStatus.failed) {
      return;
    }

    resurrectObject();
    _autoCancelWaitingTimer?.cancel();
    _autoCancelWaitingTimer = null;

    _status = TaskExecutorStatus.active;
    _result = null;

    _executor?.dispose();

    if (_completer == null || _completer!.isCompleted) {
      _completer = Completer<Result<T>>();
    }

    final newOperator = AsyncExecutor<T>(function: _executeFunctionality, connectToZone: false);
    _executor = newOperator;

    _onTaskStart?.triggerEvent(this);

    if (_timeLimitActivity != null) {
      _timeLimitActivity!.reset();
      _timeLimitActivity!.onFinishOrInterrupt.then((isTimeout) {
        if (isTimeout) {
          cancel();
        }
      });
    }

    newOperator.waitResult(zoneValues: zoneValues).then((result) {
      if (_executor != newOperator) {
        return;
      }
      _interactiveChannel = null;
      _result = result;
      if (result.itsCorrect) {
        _status = TaskExecutorStatus.completed;
      } else {
        _status = TaskExecutorStatus.failed;
      }
      _executor = null;

      if (_completer != null && !_completer!.isCompleted) {
        _completer!.complete(result);
        _completer = null;
      }

      dispose();
    });
  }

  void reset({Map<Object?, Object?> zoneValues = const {}}) {
    dispose();
    _status = TaskExecutorStatus.inactive;
    run(zoneValues: zoneValues);
  }

  FutureResult<T> runAndWait({bool resetItsNegative = false, Map<Object?, Object?> zoneValues = const {}}) async {
    if (resetItsNegative && _status == TaskExecutorStatus.failed) {
      reset(zoneValues: zoneValues);
    } else if ((_status == TaskExecutorStatus.completed || _status == TaskExecutorStatus.failed) && _result != null) {
      return _result!;
    } else if (_status == TaskExecutorStatus.active) {
      return await _completer!.future;
    } else {
      run(zoneValues: zoneValues);
    }

    return await _completer!.future;
  }

  FutureResult<T> waitResult({bool resetItsNegative = false}) {
    if (resetItsNegative && _status == TaskExecutorStatus.failed) {
      reset();
    }

    if (_completer == null) {
      _completer = Completer<Result<T>>();
    }

    return _completer!.future;
  }

  void cancel() {
    _executor?.dispose();
    dispose();
    if (_status != TaskExecutorStatus.inactive) {
      _status = TaskExecutorStatus.failed;
      _result = NegativeResult.controller(
        code: ErrorCode.functionalityCancelled,
        message: const FixedOration(message: 'The task was canceled'),
      );
      if (_completer != null && !_completer!.isCompleted) {
        _completer!.complete(CancelationResult());
        _completer = null;
      }
    }
  }

  @override
  void performObjectDiscard() {
    if (_status == TaskExecutorStatus.active) {
      _status = TaskExecutorStatus.failed;
    } else if (_status != TaskExecutorStatus.completed && _status != TaskExecutorStatus.failed) {
      _status = TaskExecutorStatus.inactive;
    }

    _executor?.dispose();
    _executor = null;
    _interactiveChannel?.dispose();
    _interactiveChannel = null;

    _completer?.complete(CancelationResult());
    _completer = null;

    _onTaskStart?.dispose();
    _onTaskStart = null;

    _autoCancelWaitingTimer?.cancel();
    _autoCancelWaitingTimer = null;

    _timeLimitActivity?.dispose();
  }

  @override
  Result<Stream<dynamic>> getReceiver() {
    if (_interactiveChannel == null || _interactiveChannel!.itWasDiscarded) {
      return NegativeResult.controller(
        code: ErrorCode.invalidFunctionality,
        message: const FixedOration(message: 'The task is not running, no interactive channel available'),
      );
    }
    return _interactiveChannel!.getReceiver();
  }

  @override
  Result<void> sendItem(item) {
    if (_interactiveChannel == null || _interactiveChannel!.itWasDiscarded) {
      return NegativeResult.controller(
        code: ErrorCode.invalidFunctionality,
        message: const FixedOration(message: 'The task is not running, no interactive channel available'),
      );
    }
    return _interactiveChannel!.sendItem(item);
  }
}
