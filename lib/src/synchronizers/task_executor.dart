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

  TaskExecutor({required this.functionality});

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
    _status = TaskExecutorStatus.active;
    _result = null;

    _executor?.dispose();

    if (_completer == null || _completer!.isCompleted) {
      _completer = Completer<Result<T>>();
    }

    final newOperator = AsyncExecutor<T>(function: _executeFunctionality, connectToZone: false);
    _executor = newOperator;

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
