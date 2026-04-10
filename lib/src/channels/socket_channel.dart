import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:maxi_framework/maxi_framework.dart';
import 'package:rxdart/rxdart.dart';

class SocketChannel with DisposableMixin, AsynchronouslyInitializedMixin, LifecycleHub implements Channel<Uint8List, Uint8List> {
  final dynamic host;
  final int port;
  final Duration autoclose;

  late Socket _nativeSocket;

  late StreamController<Uint8List> _receiverController;
  MaxiTimer? _autocloseTimer;

  int _clients = 0;

  SocketChannel({required this.host, required this.port, this.autoclose = Duration.zero});

  @override
  Future<Result<void>> performInitialize() async {
    _clients = 0;
    final socketResult = await Socket.connect(host, port).asResCatchException(
      onException: (ex, st) => NegativeResult.controller(
        code: ErrorCode.externalFault,
        message: FlexibleOration(message: 'Failed to connect to socket: %1', textParts: [ex]),
      ),
    );

    if (socketResult.itsFailure) return socketResult.cast();

    _nativeSocket = lifecycleScope.joinManualDisposableObject<Socket>(
      socketResult.content,
      onDisponse: (socket) {
        socket.close().whenComplete(() => socket.destroy());
      },
    );
    //_nativeSocket.setOption(SocketOption.tcpNoDelay, true);
    _receiverController = lifecycleScope.joinStreamController(StreamController<Uint8List>.broadcast());
    lifecycleScope.waitFuture(
      function: () => _nativeSocket.done.whenComplete(() {
        dispose();
      }),
    );
    _nativeSocket.listen(
      (data) {
        _receiverController.add(data);
      },
      onError: (ex, st) {
        _receiverController.addError(
          ExceptionResult(
            exception: ex,
            stackTrace: st,
            message: const FixedOration(message: 'An error occurred in the socket connection'),
          ),
        );
        dispose();
      },

      onDone: () {
        dispose();
      },
    );

    if (autoclose != Duration.zero) {
      _autocloseTimer = lifecycleScope.joinDisposableObject(MaxiTimer());
      _updateTimer();
    }

    return voidResult;
  }

  void _updateTimer() {
    if (autoclose != Duration.zero && _clients > 0 && !itWasDiscarded) {
      _autocloseTimer?.startOrReset(
        duration: autoclose,
        payload: null,
        onFinish: (_) {
          dispose();
        },
      );
    }
  }

  @override
  Result<Stream<Uint8List>> getReceiver() {
    if (isInitialized) {
      _clients++;
      return _receiverController.stream.doOnListen(_onListener).doOnCancel(_onCancelClient).asResultValue();
    }

    final controller = lifecycleScope.joinStreamController(StreamController<Uint8List>());

    initialize()
        .onCorrectFutureVoid((_) {
          _receiverController.stream.listen(controller.add, onDone: controller.close);
        })
        .injectNegativeLogic((error) {
          controller.addError(error);
          controller.close();
        });

    return controller.stream.doOnListen(_onListener).doOnCancel(_onCancelClient).asResultValue();
  }

  void _onListener() {
    _clients++;
    _autocloseTimer?.cancel();
    _updateTimer();
  }

  void _onCancelClient() {
    _clients--;
    _updateTimer();
  }

  @override
  Result<void> sendItem(Uint8List item) {
    if (!isInitialized) {
      return NegativeResult.controller(
        code: ErrorCode.uninitializedFunctionality,
        message: const FixedOration(message: 'Socket is not initialized yet'),
      );
    }

    _autocloseTimer?.cancel();

    final result = volatileFunction(
      error: (ex, st) => ExceptionResult(
        exception: ex,
        stackTrace: st,
        message: const FixedOration(message: 'Failed to send data through socket'),
      ),
      function: () => _nativeSocket.add(item),
    );

    _updateTimer();

    return result;
  }

  FutureResult<void> sendFlushItem(Uint8List item) async {
    final initResult = await initialize();
    if (initResult.itsFailure) return initResult.cast();

    final sendResult = volatileFunction(
      error: (ex, st) => ExceptionResult(
        exception: ex,
        stackTrace: st,
        message: const FixedOration(message: 'Failed to send data through socket'),
      ),
      function: () async {
        _autocloseTimer?.cancel();
        _nativeSocket.add(item);
      },
    );

    if (sendResult.itsFailure) {
      _autocloseTimer?.cancel();
      return sendResult.cast();
    }

    return _nativeSocket.flush().toFutureResult(errorMessage: const FixedOration(message: 'Failed to flush socket after sending data')).whenComplete(() => _updateTimer());
  }
}
