import 'dart:developer';

import 'package:maxi_framework/maxi_framework.dart';
import 'package:meta/meta.dart';

abstract interface class Disposable {
  bool get itWasDiscarded;
  TinyEvent<dynamic> get onDispose;

  void dispose();
}

mixin DisposableMixin implements Disposable {
  bool _itWasDiscarded = false;
  TinyEventManager? _onDisposeEventManager;

  @override
  bool get itWasDiscarded => _itWasDiscarded;

  @override
  TinyEvent<dynamic> get onDispose {
    _onDisposeEventManager ??= TinyEventManager();

    return _onDisposeEventManager!.createEvent(temporal: true);
  }

  //void snagOnAnotherObject({required Disposable patern}) {
  //  patern.onDispose.whenComplete(dispose);
  //}

  @override
  @nonVirtual
  void dispose() {
    maxi_dispose();
  }

  @protected
  void performObjectDiscard();

  @protected
  @nonVirtual
  void resurrectObject() {
    if (!_itWasDiscarded) {
      return;
    }

    _onDisposeEventManager ??= TinyEventManager();

    _itWasDiscarded = false;
    performResurrection();
  }

  @protected
  @nonVirtual
  Result<void> failIfItsDiscarded() {
    if (_itWasDiscarded) {
      return NegativeResult.controller(
        code: ErrorCode.discontinuedFunctionality,
        message: const FixedOration(message: 'The object was discarded and can not be used anymore'),
      );
    } else {
      return voidResult;
    }
  }

  @protected
  @mustCallSuper
  void performResurrection() {
    _itWasDiscarded = false;
  }

  @nonVirtual
  @internal
  // ignore: non_constant_identifier_names
  void maxi_dispose() {
    if (_itWasDiscarded) {
      return;
    }

    _itWasDiscarded = true;

    try {
      performObjectDiscard();
    } catch (ex, st) {
      log('Discarding object of type $runtimeType failed; the error was: $ex.\nStack: $st');
    }
    _onDisposeEventManager?.triggerEvent(this);
    _onDisposeEventManager?.dispose();
    _onDisposeEventManager = null;
  }
}
