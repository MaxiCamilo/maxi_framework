import 'dart:async';
import 'dart:developer';

import 'package:maxi_framework/src/error_handling/error_code.dart';
import 'package:maxi_framework/src/error_handling/result.dart';
import 'package:maxi_framework/src/language/oration.dart';
import 'package:meta/meta.dart';

abstract interface class Disposable {
  bool get itWasDiscarded;
  Future<dynamic> get onDispose;

  void dispose();
}

mixin DisposableMixin implements Disposable {
  bool _itWasDiscarded = false;
  Completer? _onDisposeCompleter;

  @override
  bool get itWasDiscarded => _itWasDiscarded;

  @override
  Future<dynamic> get onDispose {
    if (_onDisposeCompleter == null || _onDisposeCompleter!.isCompleted) {
      _onDisposeCompleter = Completer();
    }

    return _onDisposeCompleter!.future;
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

    if (_onDisposeCompleter != null && _onDisposeCompleter!.isCompleted) {
      _onDisposeCompleter = null;
    }

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
  void performResurrection() {}

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
    _onDisposeCompleter?.complete();
    _onDisposeCompleter = null;
  }
}
