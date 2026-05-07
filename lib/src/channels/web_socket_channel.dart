import 'dart:typed_data';

import 'package:maxi_framework/maxi_framework.dart';

class SocketChannel with DisposableMixin, AsynchronouslyInitializedMixin, LifecycleHub implements Channel<Uint8List, Uint8List> {
  final dynamic host;
  final int port;
  final Duration autoclose;
  final Duration timeout;

  SocketChannel({required this.host, required this.port, required this.autoclose, required this.timeout});

  @override
  Result<Stream<Uint8List>> getReceiver() {
    return NegativeResult.controller(
      code: ErrorCode.implementationFailure,
      message: const FixedOration(message: 'The getReceiver method is not implemented for the web platform'),
    );
  }

  @override
  Future<Result<void>> performInitialize() async {
    return NegativeResult.controller(
      code: ErrorCode.implementationFailure,
      message: const FixedOration(message: 'The performInitialize method is not implemented for the web platform'),
    );
  }

  @override
  Result<void> sendItem(Uint8List item) {
    return NegativeResult.controller(
      code: ErrorCode.implementationFailure,
      message: const FixedOration(message: 'The getReceiver method is not implemented for the web platform'),
    );
  }
}
