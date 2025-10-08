import 'dart:async';

import 'package:maxi_framework/maxi_framework.dart';

class Semaphore with DisposableMixin, InitializableMixin {
  late List<Completer<void>> _queue;

  bool _isBusy = false;

  bool get isBusy => _isBusy;

  @override
  Result<void> performInitialization() {
    _queue = [];
    _isBusy = false;

    return positiveVoidResult;
  }

  Future<T> execute<T>(FutureOr<T> Function() function) async {
    initialize();
    await _checkIfBusy();

    try {
      _isBusy = true;
      return await function();
    } finally {
      if (_queue.isNotEmpty) {
        final next = _queue.removeAt(0);
        next.complete();
      } else {
        _isBusy = false;
      }
    }
  }

  Future<void> _checkIfBusy() async {
    await Future.delayed(Duration.zero);
    if (_isBusy) {
      final waiter = Completer();
      _queue.add(waiter);
      await waiter.future;
    }
  }

  Future<Result<T>> executeWithParentController<T>({
    required FutureOr<Result<T>> Function(ParentController heart) function,
    ParentController? parentController,
    bool disposeWhenEnd = true,
    void Function(ParentController)? onCalled,
  }) {
    return execute(() async {
      final heart = parentController ?? ParentController();

      if (heart.itWasDiscarded) {
        return CancelationResult(cancelationStackTrace: StackTrace.current);
      }

      try {
        if (onCalled != null) {
          onCalled(heart);
        }
        return await function(heart);
      } finally {
        if (disposeWhenEnd || parentController == null) {
          heart.dispose();
        }
      }
    });
  }

  FuturePackWaiter<T> executeInteractiveFunctionality<I, T>({required InteractiveFunctionality<I, T> functionality, void Function(I x)? onItem}) {
    return executeCancelableFunction<T>(function: functionality.buildExecutor().execute(onItem: onItem));
  }

  FuturePackWaiter<T> executeCancelableFunction<T>({required AsyncResult<T> function, Result? Function()? onCancel}) {
    initialize();
    final whenDisponse = <Future>[];

    late final FuturePackWaiter<T> waiter;

    waiter = FuturePackWaiter<T>(
      onCancel: onCancel,
      function: () async {
        late final Result<T> content;

        await _checkIfBusy();

        if (itWasDiscarded || waiter.itWasDiscarded) {
          return CancelationResult(cancelationStackTrace: StackTrace.current);
        }

        try {
          _isBusy = true;
          content = await function.waitResult();
        } finally {
          if (_queue.isNotEmpty) {
            final next = _queue.removeAt(0);
            next.complete();
          } else {
            _isBusy = false;
          }
        }
        if (whenDisponse.isEmpty) {
          await Future.delayed(Duration.zero);
        }
        whenDisponse.lambda((x) => x.ignore());
        whenDisponse.clear();

        return content;
      },
    );

    whenDisponse.add(
      onDispose.whenComplete(() {
        waiter.dispose();
        function.dispose();
      }),
    );

    whenDisponse.add(
      waiter.onDispose.whenComplete(() {
        function.dispose();
      }),
    );

    return waiter;
  }

  @override
  void performObjectDiscard() {}
}
