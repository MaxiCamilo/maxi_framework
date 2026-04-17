import 'dart:async';

import 'package:maxi_framework/maxi_framework.dart';

class CircularChannel<T> with DisposableMixin implements Channel<T, T> {
  final StreamController<T> _controller = StreamController<T>.broadcast();

  @override
  Result<Stream<T>> getReceiver() {
    if (itWasDiscarded) {
      return NegativeResult.controller(
        code: ErrorCode.discontinuedFunctionality,
        message: const FixedOration(message: 'This channel was discarded and cannot be used to receive items'),
      );
    }

    return _controller.stream.asResultValue();
  }

  @override
  Result<void> sendItem(T item) {
    if (itWasDiscarded) {
      return NegativeResult.controller(
        code: ErrorCode.discontinuedFunctionality,
        message: const FixedOration(message: 'This channel was discarded and cannot be used to send items'),
      );
    }

    _controller.add(item);
    return voidResult;
  }

  @override
  void performObjectDiscard() {
    _controller.close();
  }
}
