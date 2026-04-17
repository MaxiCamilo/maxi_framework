import 'dart:async';
import 'dart:developer';

import 'package:maxi_framework/maxi_framework.dart';

class BidirectionalChannel<R, S> with DisposableMixin, InitializableMixin implements Channel<R, S> {
  final bool _reusable;
  final bool _onlyOneReceiver;

  _BidirectionalChillChannel<S, R>? _chillChannel;

  StreamController<R>? _controller;

  bool _wasReceiverObtained = false;

  @override
  bool get canBeRecycled => _reusable;

  BidirectionalChannel({bool reusable = false, bool onlyOneReceiver = true}) : _reusable = reusable, _onlyOneReceiver = onlyOneReceiver;

  @override
  Result<void> performInitialization() {
    _wasReceiverObtained = false;

    _chillChannel = _BidirectionalChillChannel<S, R>(parent: this);
    _controller = StreamController<R>.broadcast();

    _chillChannel!.onDispose.whenComplete(dispose);

    return voidResult;
  }

  @override
  Result<Stream<R>> getReceiver() => initialize().onCorrect((_) {
    if (_onlyOneReceiver && _wasReceiverObtained) {
      return NegativeResult.controller(
        code: ErrorCode.discontinuedFunctionality,
        message: const FixedOration(message: 'This channel is configured to only allow one receiver, and it was already obtained'),
      );
    }

    return _controller!.stream.asResultValue();
  });

  @override
  Result<void> sendItem(S item) => initialize().onCorrect((_) {
    if (_chillChannel == null) {
      return NegativeResult.controller(
        code: ErrorCode.implementationFailure,
        message: const FixedOration(message: 'The channel was not properly initialized'),
      );
    }

    _chillChannel!._receiveFromParent(item);
    return voidResult;
  });

  Result<Channel<S, R>> buildChild() => initialize().onCorrect((_) {
    if (_onlyOneReceiver && _wasReceiverObtained) {
      return NegativeResult.controller(
        code: ErrorCode.discontinuedFunctionality,
        message: const FixedOration(message: 'This channel is configured to only allow one receiver, and it was already obtained'),
      );
    }
    _wasReceiverObtained = true;
    return _chillChannel!.asResultValue();
  });

  @override
  void performObjectDiscard() {
    _chillChannel?.dispose();
    _controller?.close();
    _chillChannel = null;
    _controller = null;
  }

  void _receiveFromChild(R item) {
    if (itWasDiscarded) {
      log('[BidirectionalChannel] Trying to receive an item from child, but this channel was already discarded');
      return;
    }

    _controller?.add(item);
  }
}

class _BidirectionalChillChannel<R, S> with DisposableMixin implements Channel<R, S> {
  final BidirectionalChannel<S, R> _parent;

  final StreamController<R> _controller = StreamController<R>.broadcast();

  _BidirectionalChillChannel({required BidirectionalChannel<S, R> parent}) : _parent = parent;

  @override
  Result<Stream<R>> getReceiver() {
    if (itWasDiscarded) {
      return NegativeResult.controller(
        code: ErrorCode.discontinuedFunctionality,
        message: const FixedOration(message: 'This channel was discarded and cannot be used to receive items'),
      );
    }

    return _controller.stream.asResultValue();
  }

  @override
  Result<void> sendItem(S item) {
    if (itWasDiscarded) {
      return NegativeResult.controller(
        code: ErrorCode.discontinuedFunctionality,
        message: const FixedOration(message: 'This channel was discarded and cannot be used to send items'),
      );
    }

    _parent._receiveFromChild(item);
    return voidResult;
  }

  void _receiveFromParent(R item) {
    if (itWasDiscarded) {
      log('[BidirectionalChillChannel] Trying to receive an item from parent, but this channel was already discarded');
      return;
    }

    _controller.add(item);
  }

  @override
  void performObjectDiscard() {
    _controller.close();
  }
}
