import 'dart:async';

import 'package:maxi_framework/maxi_framework.dart';
import 'package:meta/meta.dart';

abstract interface class AsynchronouslyInitialized implements Disposable {
  bool get isInitialized;
  Future<Result<void>> initialize();
}

mixin AsynchronouslyInitializedMixin on DisposableMixin implements AsynchronouslyInitialized {
  bool _isInitialized = false;
  bool _itWasDiscarded = false;
  Completer? _onDisposeCompleter;
  Mutex? _mutex;

  @override
  bool get itWasDiscarded => _itWasDiscarded;

  @override
  bool get isInitialized => _isInitialized;

  @protected
  Future<Result<void>> performInitialize();

  @override
  @nonVirtual
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
  @override
  void performObjectDiscard() {
    _itWasDiscarded = true;
    if (_isInitialized) {
      _isInitialized = false;
      performInitializedObjectDiscard();
    } else {
      performUnitializedObjectDiscard();
    }
    _isInitialized = false;
  }

  @protected
  void performUnitializedObjectDiscard() {}

  @protected
  void performInitializedObjectDiscard() {}

  @override
  Future<dynamic> get onDispose {
    _mutex ??= Mutex();
    if (_onDisposeCompleter == null || _onDisposeCompleter!.isCompleted) {
      _onDisposeCompleter = Completer();
    }

    return _onDisposeCompleter!.future;
  }

  @override
  // ignore: invalid_override_of_non_virtual_member because we want to prevent subclasses from overriding dispose without using the mutex
  void dispose() {
    if (_mutex != null) {
      _mutex!.execute(maxi_dispose);
    }
  }
}
