import 'dart:async';

import 'package:maxi_framework/maxi_framework.dart';
import 'package:meta/meta.dart';

abstract interface class InteractiveFunctionalityExecutor<I, T> implements Disposable {
  Stream<I> get textStream;

  AsyncResult<T> execute({void Function(I x)? onItem});

  Future<Result<T>> executeAsFuture({void Function(I x)? onItem});
}

abstract interface class InteractiveFunctionality<I, T> {
  InteractiveFunctionalityExecutor<I, T> buildExecutor();
}

typedef TextableFunctionalityMixin<T> = InteractiveFunctionalityMixin<Oration, T>;

mixin InteractiveFunctionalityMixin<I, T> implements InteractiveFunctionality<I, T> {
  @protected
  Oration get functionalityName => FixedOration(message: runtimeType.toString());

  @protected
  FutureOr<Result<T>> runFuncionality({required void Function(I x) sendItem, required FutureControllerContext<T> context, required ParentController heart});

  @protected
  void onError(Result<T> result) {}

  @protected
  void onPositiveResult(Result<T> result) {}

  @protected
  void onFinish(Result<T> result) {}

  @protected
  Result<T>? onException(dynamic exception, StackTrace stackTrase) => null;

  @protected
  void onCancel() {}

  @override
  InteractiveFunctionalityExecutor<I, T> buildExecutor() => _InteractiveFunctionalityMixinExecutor<I, T>(functionality: this);
}

class _InteractiveFunctionalityMixinExecutor<I, T> with DisposableMixin implements InteractiveFunctionalityExecutor<I, T> {
  final InteractiveFunctionalityMixin<I, T> functionality;

  Result<T>? _lastResult;
  FutureController<T>? _controller;
  StreamController<I>? _itemStream;

  _InteractiveFunctionalityMixinExecutor({required this.functionality});

  @override
  Stream<I> get textStream {
    _itemStream ??= StreamController<I>.broadcast();

    if (itWasDiscarded) {
      scheduleMicrotask(() {
        _itemStream?.close();
        _itemStream = null;
      });
    }

    return _itemStream!.stream;
  }

  @override
  void performObjectDiscard() {
    _controller?.dispose();
    _itemStream?.close();

    _controller = null;
    _itemStream = null;
  }

  void _sendItem(I item) {
    if (!itWasDiscarded && _itemStream != null && !_itemStream!.isClosed) {
      _itemStream?.add(item);
    }
  }

  @override
  AsyncResult<T> execute({void Function(I x)? onItem}) {
    resurrectObject();

    if (onItem != null) {
      textStream.listen(onItem);
    }
    if (_controller == null) {
      _controller = FutureController<T>(
        onDone: (_) {
          if (_lastResult == null) {
            dispose();
          }
        },
        function: (context) async {
          try {
            _lastResult = null;
            final result = await functionality.runFuncionality(sendItem: _sendItem, context: context, heart: context.heart);
            _lastResult = result;
            if (result.itsCorrect) {
              functionality.onPositiveResult(result);
            } else {
              functionality.onError(result);
            }
          } catch (ex, st) {
            final newError = functionality.onException(ex, st);
            _lastResult =
                newError ??
                ExceptionResult(
                  exception: ex,
                  stackTrace: st,
                  message: FlexibleOration(message: 'An internal error occurred in functionality %1', textParts: [functionality.functionalityName]),
                );
          } finally {
            functionality.onFinish(_lastResult!);
          }

          return _lastResult!;
        },
      );

      _controller!.onDispose.whenComplete(dispose);
    }
    return _controller!;
  }

  @override
  Future<Result<T>> executeAsFuture({void Function(I)? onItem}) {
    return execute(onItem: onItem).waitResult();
  }
}
