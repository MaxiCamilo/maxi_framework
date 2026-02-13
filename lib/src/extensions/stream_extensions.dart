import 'dart:async';

import 'package:maxi_framework/maxi_framework.dart';

Stream<T> buildStream<T>(FutureOr<Stream<T>> Function() function) async* {
  final stream = await function();
  yield* stream;
}

extension StreamExtensions<T> on Stream<T> {
  Future<Result<T>> waitItem({Duration? timeout, bool connectToZone = true}) async {
    final waiter = Completer<Result<T>>();
    Future? heartCanceled;

    final subscription = listen(
      (event) {
        if (!waiter.isCompleted) {
          waiter.complete(ResultValue(content: event));
        }
      },
      onError: (x, y) {
        if (!waiter.isCompleted) {
          if (x is Result) {
            waiter.complete(x.cast());
          } else {
            waiter.complete(
              ExceptionResult(
                exception: x,
                stackTrace: y,
                message: const FixedOration(message: 'An unknown error was emitted while waiting for a stream item'),
              ),
            );
          }
        }
      },

      onDone: () {
        if (!waiter.isCompleted) {
          waiter.complete(
            NegativeResult.controller(
              code: ErrorCode.nonExistent,
              message: FixedOration(message: 'The value flow did not return values and closed'),
            ),
          );
        }
      },
    );

    if (connectToZone) {
      final heart = LifeCoordinator.tryGetZoneHeart;
      if (heart != null) {
        if (heart.itWasDiscarded) {
          return CancelationResult();
        }
        heartCanceled = heart.onDispose.whenComplete(() {
          if (!waiter.isCompleted) {
            waiter.complete(CancelationResult());
          }
        });
      }
    }

    late final Timer? timer;
    if (timeout != null) {
      timer = Timer(timeout, () {
        if (!waiter.isCompleted) {
          waiter.complete(
            NegativeResult.controller(
              code: ErrorCode.timeout,
              message: FixedOration(message: 'The stream has not returned a value within the agreed time'),
            ),
          );
        }
      });
    }

    final result = await waiter.future;
    subscription.cancel();
    timer?.cancel();
    heartCanceled?.ignore();

    return result;
  }

  Future<Result<void>> waitFinish({required void Function(T event) onData, Function? onError, void Function()? onDone, bool? cancelOnError, bool connectToHeart = true}) {
    final completer = Completer<Result<void>>();
    Future<dynamic>? onDispose;

    final subscription = listen(
      onData,
      onError: onError,
      cancelOnError: cancelOnError,
      onDone: () {
        if (!completer.isCompleted) {
          completer.complete(voidResult);
        }
        onDispose?.ignore();
      },
    );

    if (connectToHeart) {
      final heart = LifeCoordinator.tryGetZoneHeart;
      if (heart != null) {
        onDispose = heart.onDispose.whenComplete(() {
          subscription.cancel();
        });
      }
    }

    return completer.future;
  }

  Stream<T> whenCancel({required void Function() onCancel}) {
    bool finish = false;
    final controller = StreamController<T>();

    Stream<T> fake() async* {
      yield* this;
      finish = true;
    }

    controller.addStream(fake()).whenComplete(() {
      if (!finish) {
        onCancel();
      }
      controller.close();
    });

    return controller.stream;
  }
}

extension StreamControllerExtensions<T> on StreamController<T> {
  Type get typeItemSent => T;
}
