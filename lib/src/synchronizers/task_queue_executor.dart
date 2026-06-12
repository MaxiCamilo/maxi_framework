import 'dart:async';

import 'package:maxi_framework/maxi_framework.dart';

class TaskQueueExecutor with DisposableMixin, LifecycleHub {
  StreamController<TaskExecutor>? _executionController;

  final _taskList = DisposableList<TaskExecutor>(disposeIfItsEmpty: true);

  bool get isActive => _executionController != null && !_executionController!.isClosed;

  @override
  void performResurrection() {
    super.performResurrection();
    _taskList.resurrectObject();
    _taskList.onDispose.whenComplete(dispose);
  }

  Stream<TaskExecutor> get listenToCompleteTask async* {
    _executeQueue();
    yield* _executionController!.stream;
  }

  void addTask(TaskExecutor task) {
    resurrectObject();
    task.resurrectObject();

    _taskList.add(task);
    lifecycleScope.joinDisposableObject(task);
    _executeQueue();
  }

  TaskExecutor<T> addFunctionality<T>({required Functionality<T> functionality, Duration? autoCancelWaitingExecution}) {
    final newTask = functionality.toTaskExecutor();
    if (autoCancelWaitingExecution != null) {
      newTask.closeWhenWaitingExecution(duration: autoCancelWaitingExecution);
    }
    addTask(newTask);
    return newTask;
  }

  FutureResult<T> addAndWaitTask<T>(TaskExecutor<T> task) {
    addTask(task);
    return task.waitResult(resetItsNegative: true);
  }

  FutureResult<T> addAndWaitFunctionality<T>({required Functionality<T> functionality, Duration? autoCancelWaitingExecution}) {
    final newTask = addFunctionality(functionality: functionality, autoCancelWaitingExecution: autoCancelWaitingExecution);
    return newTask.waitResult(resetItsNegative: true);
  }

  void _executeQueue() {
    if (isActive) return;

    _executionController = lifecycleScope.joinStreamController(StreamController<TaskExecutor>.broadcast());
    scheduleMicrotask(() async {
      if (itWasDiscarded) {
        return;
      }
      while (_taskList.isNotEmpty) {
        final task = _taskList.first;

        await task.runAndWait(resetItsNegative: true);
        _executionController?.add(task);

        if (itWasDiscarded) {
          return;
        }

        if (_taskList.isNotEmpty && _taskList.first == task) {
          _taskList.removeAt(0);
        }
      }

      _executionController?.close();
      _executionController = null;
    });
  }

  @override
  void performObjectDiscard() {
    _taskList.dispose();
    _executionController = null;
  }
}
