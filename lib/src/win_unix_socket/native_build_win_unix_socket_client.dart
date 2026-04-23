import 'dart:async';
import 'dart:typed_data';

import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_framework/src/win_unix_socket/implementation/win_unix_socket.dart';
import 'package:maxi_framework/src/win_unix_socket/win_unix_socket.dart';

class BuildWinUnixSocketClient implements SyncFunctionality<WinUnixSocketClient> {
  final String path;

  const BuildWinUnixSocketClient({required this.path});

  @override
  Result<WinUnixSocketClient> execute() {
    return _WinUnixSocketClient(path: path).asResultValue();
  }

}

class _WinUnixSocketClient extends WinUnixSocketClient with LifecycleHub {
  final String path;

  NativeWinUnixSocket? _nativeSocket;

  late StreamController<Uint8List> _receiverController;

  _WinUnixSocketClient({required this.path});

  @override
  Future<Result<void>> performInitialize() async {
    final socketResult = await NativeWinUnixSocket.connect(path).toFutureResult(
      errorMessage: FlexibleOration(message: 'An error occurred while trying to generate a unix socket on %1', textParts: [path]),
    );

    if (socketResult.itsFailure) {
      return socketResult.cast();
    }

    _nativeSocket = socketResult.content;

    _receiverController = lifecycleScope.joinStreamController(StreamController<Uint8List>.broadcast());

    _nativeSocket!.stream.listen((data) => _receiverController.add(data), onError: (error) => _receiverController.addError(error), onDone: () => dispose());

    return voidResult;
  }

  @override
  Result<Stream<Uint8List>> getReceiver() {
    return buildReceiver().asResultValue();
  }

  Stream<Uint8List> buildReceiver() async* {
    final initResult = await initialize();
    if (initResult.itsFailure) {
      yield* Stream.error(initResult);
      return;
    }

    yield* _receiverController.stream;
  }

  @override
  Result<void> sendItem(Uint8List item) {
    if (!itWasDiscarded) {
      return NegativeResult.controller(
        code: ErrorCode.discontinuedFunctionality,
        message: const FixedOration(message: 'This functionality has been discontinued and can no longer be used'),
      );
    }

    if (!isInitialized) {
      return NegativeResult.controller(
        code: ErrorCode.invalidFunctionality,
        message: const FixedOration(message: 'The socket must be initialized before sending items'),
      );
    }

    return tryFunction(const FixedOration(message: 'An error occurred while sending the item'), () => _nativeSocket!.sink.add(item));
  }

  @override
  void performInitializedObjectDiscard() {
    super.performInitializedObjectDiscard();

    _nativeSocket?.close();
    _nativeSocket = null;
  }
}
