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
  LifeCoordinator? _heart;

  @override
  bool get itWasDiscarded => _itWasDiscarded;

  @protected
  LifeCoordinator get heart {
    _heart ??= LifeCoordinator();
    return _heart!;
  }

  @protected
  Future<Result<void>> performInitialize();

  @override
  Future<Result<void>> initialize() {
    _mutex ??= Mutex();
    return _mutex!.execute(() async {
      if (_isInitialized) {
        return voidResult;
      }

      try {
        _itWasDiscarded = false;
        final result = await performInitialize();
        if (result.itsCorrect) {
          _isInitialized = true;
        } else {
          _heart?.dispose();
          _heart = null;
          dispose();
        }
        return result;
      } catch (ex, st) {
        _heart?.dispose();
        _heart = null;
        final result = ExceptionResult(
          exception: ex,
          stackTrace: st,
          message: FlexibleOration(message: 'An internal error occurred while trying to initialize the functionality %1', textParts: [runtimeType.toString()]),
        );
        dispose();

        return result;
      }
    });
  }

  @protected
  @mustCallSuper
  void performObjectDiscard(bool itsWasInitialized) {
    _heart?.dispose();
    _heart = null;
  }

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
