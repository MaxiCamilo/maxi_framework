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
  Mutex? _mutex;

  @override
  bool get itWasDiscarded => _itWasDiscarded;

  @protected
  Future<Result<void>> performInitialize();

  @override
  Future<Result<void>> initialize() {
    _mutex ??= Mutex();
    return _mutex!.execute(() async {
      if (_isInitialized) {
        if (_mutex!.onlyHasOne) {
          _mutex = null;
        }
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
        if (_mutex!.onlyHasOne) {
          _mutex = null;
        }
        return result;
      } catch (ex, st) {
        final result = ExceptionResult(
          exception: ex,
          stackTrace: st,
          message: FlexibleOration(message: 'An internal error occurred while trying to initialize the functionality %1', textParts: [runtimeType.toString()]),
        );
        dispose();
        if (_mutex!.onlyHasOne) {
          _mutex = null;
        }

        return result;
      }
    });
  }

  @protected
  void performObjectDiscard(bool itsWasInitialized) {}

  @override
  Future<dynamic> get onDispose {
    _mutex ??= Mutex();
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
    if (_mutex != null) {
      _mutex!.execute(maxi_dispose);
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

    try {
      performObjectDiscard(_isInitialized);
    } catch (ex, st) {
      log('Discarding object of type $runtimeType failed; the error was: $ex.\nStack: $st');
    }

    _isInitialized = false;
    _onDisposeCompleter?.complete();
    _onDisposeCompleter = null;
  }
}
