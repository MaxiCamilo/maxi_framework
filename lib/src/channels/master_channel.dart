import 'dart:async';

import 'package:maxi_framework/maxi_framework.dart';
import 'package:meta/meta.dart';

class MasterChannel<R, S> with DisposableMixin, InitializableMixin implements Channel<R, S> {
  final bool reactivated;

  bool _isClosed = false;

  late StreamController<R> _receiverController;

  late List<_SlaveChannel<S, R>> _slavers;

  MasterChannel({this.reactivated = false});

  @override
  Result<void> performInitialization() {
    if (_isClosed && !reactivated) {
      return NegativeResult.controller(
        code: ErrorCode.implementationFailure,
        message: FixedOration(message: 'This channel has been closed and cannot be opened'),
      );
    }

    _slavers = <_SlaveChannel<S, R>>[];
    _receiverController = StreamController<R>.broadcast();

    return voidResult;
  }

  @override
  Result<Stream<R>> getReceiver() {
    final initializeResult = initialize();
    if (initializeResult.itsFailure) return initializeResult.cast();

    return ResultValue(content: _receiverController.stream);
  }

  Result<Channel<S, R>> buildConnector() {
    final initializeResult = initialize();
    if (initializeResult.itsFailure) return initializeResult.cast();

    final newSlaver = _SlaveChannel<S, R>(master: this);

    newSlaver.onDispose.whenComplete(() => _slavers.remove(newSlaver));
    _slavers.add(newSlaver);

    return ResultValue(content: newSlaver);
  }

  @override
  Result<void> sendItem(S item) {
    final initializeResult = initialize();
    if (initializeResult.itsFailure) return initializeResult.cast();

    _slavers.lambda((x) => x.receiveMasterItem(item));

    return voidResult;
  }

  @override
  void performObjectDiscard() {
    _isClosed = true;

    final clone = _slavers.toList(growable: false);
    _slavers.clear();
    clone.lambda((x) => x.dispose());

    _receiverController.close();
  }

  @protected
  Result<void> receiveSlaveItem({required R item}) {
    if (!itWasDiscarded) {
      _receiverController.add(item);
    }

    return voidResult;
  }
}

class _SlaveChannel<R, S> with DisposableMixin implements Channel<R, S> {
  final MasterChannel<S, R> master;

  late final StreamController<R> _receiverController;

  _SlaveChannel({required this.master}) {
    _receiverController = StreamController<R>.broadcast();
  }

  @protected
  void receiveMasterItem(R item) {
    if (!itWasDiscarded) {
      _receiverController.add(item);
    }
  }

  Result<void> _checkIfDispose() {
    if (itWasDiscarded) {
      return NegativeResult.controller(
        code: ErrorCode.implementationFailure,
        message: FixedOration(message: 'This channel has been closed'),
      );
    }

    return voidResult;
  }

  @override
  Result<Stream<R>> getReceiver() {
    final checkDispose = _checkIfDispose();
    if (checkDispose.itsFailure) return checkDispose.cast();

    return ResultValue(content: _receiverController.stream);
  }

  @override
  Result<void> sendItem(S item) {
    final checkDispose = _checkIfDispose();
    if (checkDispose.itsFailure) return checkDispose.cast();

    return master.receiveSlaveItem(item: item);
  }

  @override
  void performObjectDiscard() {
    _receiverController.close();
  }
}
