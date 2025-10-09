import 'dart:async';
import 'dart:developer';

import 'package:maxi_framework/maxi_framework.dart';

typedef TextableResult<T> = InteractiveResult<Oration, T>;

abstract interface class InteractiveResult<I, T> implements AsyncResult<T> {
  static const kItemSender = #maxiInteractiveFunctionalitySender;

  Stream<I> get itemStream;

  @override
  Future<Result<T>> waitResult({void Function(I)? onItem, Map<Object?, Object?> zoneValues = const {}});

  static void sendItem<T>(T item) {
    final sender = Zone.current[kItemSender];

    if (sender == null) {
      log('[InteractiveFunctionality] This zone has no item sender');
      return;
    }

    if (sender is void Function(dynamic)) {
      sender(item);
    } else {
      log('[InteractiveFunctionality] A sender of type a function was expected, but the sender for this zone is %${sender.runtimeType}');
    }
  }
}

class InteractiveExecutor<I, T> with DisposableMixin implements InteractiveResult<I, T> {
  final AsyncExecutor<T> function;

  StreamController<I>? _streamController;

  Future? _connectedDisposeFunction;

  InteractiveExecutor({required this.function});

  factory InteractiveExecutor.function({required FutureOr<T> Function() function, void Function()? onCancel, Oration? exceptionMessage, void Function(ParentController)? onHeartCreated}) => InteractiveExecutor(
    function: AsyncExecutor.function(function: function, exceptionMessage: exceptionMessage, onCancel: onCancel, onHeartCreated: onHeartCreated),
  );

  @override
  bool get isActive => itWasDiscarded;

  @override
  Stream<I> get itemStream {
    if (itWasDiscarded) {
      final fake = StreamController<I>();
      scheduleMicrotask(() => fake.close());
      return fake.stream;
    }

    if (_streamController == null || _streamController!.isClosed) {
      _streamController = StreamController<I>.broadcast();
    }

    return _streamController!.stream;
  }

  @override
  Future<Result<T>> waitResult({void Function(I)? onItem, Map<Object?, Object?> zoneValues = const {}}) {
    resurrectObject();

    _connectedDisposeFunction ??= function.onDispose.whenComplete(dispose);

    if (_streamController == null || _streamController!.isClosed) {
      _streamController = StreamController<I>.broadcast();
    }

    if (onItem != null) {
      _streamController!.stream.listen(onItem);
    }

    return function.waitResult(zoneValues: {InteractiveResult.kItemSender: _receiveItem, ...zoneValues});
  }

  void _receiveItem(dynamic item) {
    if (item is I) {
      if (_streamController == null || _streamController!.isClosed) {
        log('[InteractiveFunctionality] The item\'s receiver was closed');
      } else {
        _streamController!.add(item);
      }
    } else {
      log('[InteractiveFunctionality] Received an item of type ${item.runtimeType}, but an item of type $T was expected');
    }
  }

  @override
  void performObjectDiscard() {
    _streamController?.close();
    _connectedDisposeFunction?.ignore();
    _connectedDisposeFunction = null;
  }
}
