import 'dart:async';
import 'dart:ffi';
import 'dart:io' show File;
import 'dart:isolate';

import 'package:ffi/ffi.dart';

import 'win_unix_socket.dart';
import 'winsock_ffi.dart';

/// Parámetros para el isolate de accept
class _AcceptArgs {
  final int serverHandle;
  final SendPort sendPort;
  _AcceptArgs(this.serverHandle, this.sendPort);
}

/// Mensaje enviado desde el isolate de accept al stream principal
sealed class _AcceptMsg {}

class _NewConnectionMsg extends _AcceptMsg {
  final int clientHandle;
  _NewConnectionMsg(this.clientHandle);
}

class _AcceptErrorMsg extends _AcceptMsg {
  final String message;
  final int wsaError;
  _AcceptErrorMsg(this.message, this.wsaError);
}

class _AcceptStopMsg extends _AcceptMsg {}

// Top-level para Isolate.spawn
void _acceptLoop(_AcceptArgs args) {
  final ws = Winsock.instance;
  final addrPtr = calloc<SockaddrUn>();
  final addrLenPtr = calloc<Int32>()..value = sizeOf<SockaddrUn>();

  try {
    while (true) {
      // accept() es bloqueante — por eso está en su propio isolate
      final client = ws.accept(args.serverHandle, addrPtr, addrLenPtr);

      if (client == INVALID_SOCKET) {
        final err = ws.getLastError();
        // WSAEINTR (10004) significa que cerramos el server socket
        // intencionalmente para detener el loop
        if (err == 10004) {
          args.sendPort.send(_AcceptStopMsg());
        } else {
          args.sendPort.send(_AcceptErrorMsg('accept() failed', err));
        }
        break;
      }

      args.sendPort.send(_NewConnectionMsg(client));
      // Resetear el addrlen para la próxima llamada
      addrLenPtr.value = sizeOf<SockaddrUn>();
    }
  } finally {
    calloc.free(addrPtr);
    calloc.free(addrLenPtr);
  }
}

// ─── WinUnixServerSocket ──────────────────────────────────────────────────────

/// Servidor que escucha conexiones entrantes en un Unix socket en Windows.
///
/// Emite un [NativeWinUnixSocket] por cada cliente que se conecta.
///
/// Ejemplo de uso:
/// ```dart
/// final server = await WinUnixServerSocket.bind(r'C:\tmp\grpc.sock');
/// await for (final client in server.connections) {
///   handleClient(client); // no await — cada cliente es independiente
/// }
/// ```
class WinUnixServerSocket {
  final int _handle;
  final String path;
  final Winsock _ws;

  final StreamController<NativeWinUnixSocket> _connectionsController;
  Isolate? _acceptIsolate;
  ReceivePort? _receivePort;

  WinUnixServerSocket._(this._handle, this.path, this._ws)
      : _connectionsController = StreamController<NativeWinUnixSocket>();

  /// Stream de conexiones entrantes. Cada elemento es un [NativeWinUnixSocket]
  /// listo para usar.
  Stream<NativeWinUnixSocket> get connections => _connectionsController.stream;

  /// Crea el socket, hace bind+listen y arranca el loop de aceptación.
  ///
  /// [path] es el path del archivo socket, ej: `C:\tmp\myapp.sock`
  /// [backlog] es la cola de conexiones pendientes (default 128)
  /// [deleteOnBind] elimina el archivo si ya existe antes de hacer bind
  static Future<WinUnixServerSocket> bind(
    String path, {
    int backlog = 128,
    bool deleteOnBind = true,
  }) async {
    final ws = Winsock.instance;

    // Eliminar socket file previo si existe
    if (deleteOnBind) {
      final f = File(path);
      if (f.existsSync()) f.deleteSync();
    }

    final handle = ws.socket(AF_UNIX, SOCK_STREAM, 0);
    if (handle == INVALID_SOCKET) {
      throw SocketException('socket() failed');
    }

    // SO_REUSEADDR para poder reusar el path rápidamente
    final optVal = calloc<Int32>()..value = 1;
    try {
      ws.setsockopt(handle, SOL_SOCKET, SO_REUSEADDR, optVal, sizeOf<Int32>());
    } finally {
      calloc.free(optVal);
    }

    // bind
    final addrPtr = calloc<SockaddrUn>();
    try {
      _fillSockaddr(addrPtr, path);
      final bindResult = ws.bind(handle, addrPtr, sizeOf<SockaddrUn>());
      if (bindResult == SOCKET_ERROR) {
        ws.closeSocket(handle);
        throw SocketException('bind() failed on $path');
      }
    } finally {
      calloc.free(addrPtr);
    }

    // listen
    final listenResult = ws.listen(handle, backlog);
    if (listenResult == SOCKET_ERROR) {
      ws.closeSocket(handle);
      throw SocketException('listen() failed on $path');
    }

    final server = WinUnixServerSocket._(handle, path, ws);
    await server._startAcceptLoop();
    return server;
  }

  Future<void> _startAcceptLoop() async {
    final receivePort = ReceivePort();
    _receivePort = receivePort;

    _acceptIsolate = await Isolate.spawn(
      _acceptLoop,
      _AcceptArgs(_handle, receivePort.sendPort),
      debugName: 'WinUnixServerSocket.accept#$_handle',
    );

    receivePort.listen((msg) async {
      switch (msg) {
        case _NewConnectionMsg(:final clientHandle):
          try {
            final client = await NativeWinUnixSocket.fromHandle(clientHandle);
            if (!_connectionsController.isClosed) {
              _connectionsController.add(client);
            }
          } catch (e, st) {
            if (!_connectionsController.isClosed) {
              _connectionsController.addError(e, st);
            }
          }

        case _AcceptErrorMsg(:final message, :final wsaError):
          if (!_connectionsController.isClosed) {
            _connectionsController.addError(
              SocketException('$message (WSA error: $wsaError)'),
            );
            await _connectionsController.close();
          }
          receivePort.close();

        case _AcceptStopMsg():
          if (!_connectionsController.isClosed) {
            await _connectionsController.close();
          }
          receivePort.close();
      }
    });
  }

  /// Cierra el servidor. Las conexiones ya establecidas no se ven afectadas.
  Future<void> close() async {
    // Cerrar el server socket interrumpe el accept() bloqueante en el isolate
    _ws.shutdown(_handle, SD_BOTH);
    _ws.closeSocket(_handle);

    // Pequeña espera para que el isolate procese el WSAEINTR
    await Future.delayed(const Duration(milliseconds: 50));

    _acceptIsolate?.kill(priority: Isolate.immediate);
    _receivePort?.close();

    if (!_connectionsController.isClosed) {
      await _connectionsController.close();
    }

    // Limpiar el archivo socket
    try {
      final f = File(path);
      if (f.existsSync()) f.deleteSync();
    } catch (_) {}
  }
}

// ─── Helper (duplicado de win_unix_socket.dart para evitar dependencia circular)
void _fillSockaddr(Pointer<SockaddrUn> ptr, String path) {
  ptr.ref.sunFamily = AF_UNIX;
  final bytes = path.codeUnits;
  if (bytes.length > 107) {
    throw ArgumentError('Unix socket path demasiado largo: $path');
  }
  for (var i = 0; i < bytes.length; i++) {
    ptr.ref.sunPath[i] = bytes[i];
  }
  ptr.ref.sunPath[bytes.length] = 0;
}
