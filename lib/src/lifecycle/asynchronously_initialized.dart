import 'dart:async';
import 'dart:developer';

import 'package:maxi_framework/maxi_framework.dart';
import 'package:meta/meta.dart';

abstract interface class AsynchronouslyInitialized implements Disposable {
  bool get isInitialized;
  Future<Result<void>> initialize();
}

mixin AsynchronouslyInitializedMixin implements AsynchronouslyInitialized {
  bool _isInitialized = false;
  bool _itWasDiscarded = false;
  Completer? _onDisposeCompleter;
  Semaphore? _semaphore;

  @override
  bool get itWasDiscarded => _itWasDiscarded;

  @protected
  Future<Result<void>> performInitialize();

  @override
  Future<Result<void>> initialize() {
    _semaphore ??= Semaphore();
    return _semaphore!.execute(() async {
      if (_isInitialized) {
        return voidResult;
      }

      try {
        _itWasDiscarded = false;
        final result = await performInitialize();
        if (result.itsCorrect) {
          _isInitialized = true;
        } else {
          dispose();
        }
        return result;
      } catch (ex, st) {
        final result = ExceptionResult(exception: ex, stackTrace: st);
        dispose();

        return result;
      }
    });
  }

  @protected
  void performObjectDiscard() {}

  @override
  Future<dynamic> get onDispose {
    _semaphore ??= Semaphore();
    if (_onDisposeCompleter == null || _onDisposeCompleter!.isCompleted) {
      _onDisposeCompleter = Completer();
    }

    return _onDisposeCompleter!.future;
  }

  void snagOnAnotherObject({required Disposable patern}) {
    patern.onDispose.whenComplete(dispose);
  }

  @override
  void dispose() {
    if (_semaphore != null) {
      _semaphore!.execute(maxi_dispose);
    }
  }

  @override
  bool get isInitialized => _isInitialized;

  // ignore: non_constant_identifier_names
  void maxi_dispose() {
    if (_itWasDiscarded) {
      return;
    }

    _itWasDiscarded = true;
    _isInitialized = false;

    try {
      performObjectDiscard();
    } catch (ex, st) {
      log('Discarding object of type $runtimeType failed; the error was: $ex.\nStack: $st');
    }
    _onDisposeCompleter?.complete();
    _onDisposeCompleter = null;
  }
}
