import 'dart:async';
import 'dart:typed_data';

import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_framework/src/win_unix_socket/implementation/win_unix_server_socket.dart';
import 'package:maxi_framework/src/win_unix_socket/implementation/win_unix_socket.dart';
import 'package:maxi_framework/src/win_unix_socket/win_unix_socket.dart';

class NativeBuildWinUnixSocketServer implements SyncFunctionality<WinUnixSocketServer> {
  final String path;

  const NativeBuildWinUnixSocketServer({required this.path});

  @override
  Result<WinUnixSocketServer> execute() {
    return _WinUnixSocketServer(path: path).asResultValue();
  }
}

class _WinUnixSocketServer extends WinUnixSocketServer with LifecycleHub {
  final String path;

  WinUnixServerSocket? _server;
  StreamController<Channel<Uint8List, Uint8List>>? _newClientController;

  final _clients = <Channel<Uint8List, Uint8List>>[];

  _WinUnixSocketServer({required this.path});

  @override
  List<Channel<Uint8List, Uint8List>> get clients => _clients;

  @override
  Stream<Channel<Uint8List, Uint8List>> get newClient async* {
    final initResult = await initialize();
    if (initResult.itsFailure) {
      yield* Stream.error(initResult);
      return;
    }

    yield* _newClientController!.stream;
  }

  @override
  Future<Result<void>> performInitialize() async {
    final serverResult = await WinUnixServerSocket.bind(path).toFutureResult(
      errorMessage: FlexibleOration(message: 'An error occurred while trying to generate a unix server socket on %1', textParts: [path]),
    );

    if (serverResult.itsFailure) {
      return serverResult.cast();
    }

    _server = serverResult.content;
    _newClientController = lifecycleScope.joinStreamController(StreamController<Channel<Uint8List, Uint8List>>.broadcast());

    _server!.connections.listen(
      (client) {
        final channel = lifecycleScope.joinDisposableObject(_WinUnixSocketServerClient(socket: client));
        _clients.add(channel);
        _newClientController!.add(channel);

        channel.onDispose.then((_) => _clients.remove(channel));
      },
      onError: (error) => _newClientController!.addError(error),
      onDone: () => dispose(),
    );

    return voidResult;
  }

  @override
  void performInitializedObjectDiscard() {
    super.performInitializedObjectDiscard();

    _server?.close();
    _server = null;

    _clients.toList().lambda((x) => x.dispose());
    _clients.clear();
  }
}

class _WinUnixSocketServerClient with DisposableMixin implements Channel<Uint8List, Uint8List> {
  final NativeWinUnixSocket _socket;

  late final StreamSubscription<Uint8List> _subscription;
  late final StreamController<Uint8List> _receiverController;

  _WinUnixSocketServerClient({required NativeWinUnixSocket socket}) : _socket = socket {
    _subscription = _socket.stream.listen(
      (item) {
        if (_receiverController.isClosed) {
          return;
        }
        _receiverController.add(item);
      },
      onError: _receiverController.addError,
      onDone: () => dispose(),
    );
    _receiverController = StreamController<Uint8List>();
  }

  @override
  Result<Stream<Uint8List>> getReceiver() {
    return buildReceiver().asResultValue();
  }

  Stream<Uint8List> buildReceiver() async* {
    if (itWasDiscarded) {
      yield* Stream.error(
        NegativeResult.controller(
          code: ErrorCode.discontinuedFunctionality,
          message: const FixedOration(message: 'Cannot receive data from a discarded socket'),
        ),
      );
      return;
    }

    yield* _receiverController.stream;
  }

  @override
  Result<void> sendItem(Uint8List item) {
    if (itWasDiscarded) {
      return NegativeResult.controller(
        code: ErrorCode.discontinuedFunctionality,
        message: const FixedOration(message: 'Cannot send data to a discarded socket'),
      );
    }

    tryFunction(const FixedOration(message: 'An error occurred while sending the item'), () => _socket.sink.add(item));
    return voidResult;
  }

  @override
  void performObjectDiscard() {
    _receiverController.close();
    _subscription.cancel();
    _socket.close();
  }
}
