import 'dart:async';

import 'package:maxi_framework/maxi_framework.dart';

abstract interface class RemoteObject<T> {
  Future<Result<T>> getItem();
  Stream<T> get notifyChange;


  Future<Result<R>> execute<R>({InvocationParameters parameters = InvocationParameters.emptry, required FutureOr<R> Function(T item, InvocationParameters para) function});
  Future<Result<R>> executeResult<R>({InvocationParameters parameters = InvocationParameters.emptry, required FutureOr<Result<R>> Function(T item, InvocationParameters para) function});
}

class LocalPointer<T> with DisposableMixin implements RemoteObject<T> {
  T item;

  StreamController<T>? _notifyChangeCotroller;

  @override
  Stream<T> get notifyChange {
    resurrectObject();
    _notifyChangeCotroller ??= StreamController<T>.broadcast();

    return _notifyChangeCotroller!.stream;
  }

  

  @override
  void performObjectDiscard() {
    _notifyChangeCotroller?.close();
    _notifyChangeCotroller = null;
  }

  LocalPointer({required this.item});

  @override
  Future<Result<T>> getItem() async => ResultValue<T>(content: item);

  @override
  Future<Result<R>> execute<R>({InvocationParameters parameters = InvocationParameters.emptry, required FutureOr<R> Function(T item, InvocationParameters para) function}) async {
    return ResultValue(content: await function(item, parameters));
  }

  @override
  Future<Result<R>> executeResult<R>({InvocationParameters parameters = InvocationParameters.emptry, required FutureOr<Result<R>> Function(T item, InvocationParameters para) function}) async {
    return await function(item, parameters);
  }
}
