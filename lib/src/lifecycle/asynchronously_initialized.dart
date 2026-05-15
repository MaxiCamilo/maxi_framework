import 'dart:async';

import 'package:maxi_framework/maxi_framework.dart';
import 'package:meta/meta.dart';

abstract interface class AsynchronouslyInitialized implements Disposable {
  bool get isInitialized;
  Future<Result<void>> initialize();
}

mixin AsynchronouslyInitializedMixin on DisposableMixin implements AsynchronouslyInitialized {
  bool _isInitialized = false;
  bool _isInitializing = false;
  Mutex? _mutex;

  @override
  bool get isInitialized => _isInitialized;

  @protected
  bool get isInitializing => _isInitializing;

  @protected
  Future<Result<void>> performInitialize();

  @override
  @nonVirtual
  Future<Result<void>> initialize() {
    _mutex ??= Mutex();

    return _mutex!.execute(() async {
      if (_isInitialized) {
        if (_mutex != null && _mutex!.onlyHasOne) {
          _mutex = null;
        }
        return voidResult;
      }

      _isInitializing = true;

      try {
        resurrectObject();
        final result = await performInitialize();
        if (result.itsCorrect) {
          _isInitialized = true;
        } else {
          dispose();
        }
        if (_mutex != null && _mutex!.onlyHasOne) {
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
        if (_mutex != null && _mutex!.onlyHasOne) {
          _mutex = null;
        }

        return result;
      } finally {
        _isInitializing = false;
      }
    });
  }

  @protected
  @nonVirtual
  @override
  void performObjectDiscard() {
    if (_isInitialized) {
      _isInitialized = false;
      performInitializedObjectDiscard();
    } else {
      performUnitializedObjectDiscard();
    }

    if (_mutex != null && _mutex!.isBusy) {
      if (_mutex!.onlyHasOne) {
        final actual = _mutex!;
        _mutex = null;
        actual.execute(() async {
          _isInitialized = false;
          actual.dispose();
        });
      } else {
        final actual = _mutex!;
        _mutex = null;
        actual.execute(() async {
          actual.dispose();
        });
      }
    } else {
      _mutex = null;
    }

    _isInitialized = false;
  }

  @protected
  void performUnitializedObjectDiscard() {}

  @protected
  void performInitializedObjectDiscard() {}

  FutureResult<void> reset() async {
    if (isInitialized) {
      dispose();
    } else if (isInitializing && _mutex != null) {
      await _mutex!.executeWhenNotBusy(() async {});
      dispose();
    }

    return initialize();
  }
}
