import 'dart:async';

import 'package:maxi_framework/maxi_framework.dart';

extension StreamExtensions<T> on Stream<T> {
  Future<Result<T>> waitItem({required Duration timeout}) async {
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
            waiter.complete(ExceptionResult(exception: x, stackTrace: y));
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

    final heart = LifeCoordinator.tryGetZoneHeart;
    if (heart != null) {
      if (heart.itWasDiscarded) {
        return const  CancelationResult();
      }
      heartCanceled = heart.onDispose.whenComplete(() {
        if (!waiter.isCompleted) {
          waiter.complete(const  CancelationResult());
        }
      });
    }

    final timer = Timer(timeout, () {
      if (!waiter.isCompleted) {
        waiter.complete(
          NegativeResult.controller(
            code: ErrorCode.timeout,
            message: FixedOration(message: 'The stream has not returned a value within the agreed time'),
          ),
        );
      }
    });

    final result = await waiter.future;
    subscription.cancel();
    timer.cancel();
    heartCanceled?.ignore();

    return result;
  }
}
