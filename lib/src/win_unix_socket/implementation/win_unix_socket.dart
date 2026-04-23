import 'dart:async';
import 'dart:ffi';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import 'winsock_ffi.dart';

/// Tamaño del buffer de lectura por chunk
const int _kReadBufferSize = 65536;

/// Mensaje que el isolate de lectura envía al canal principal
sealed class _ReadMsg {}

class _DataMsg extends _ReadMsg {
  final Uint8List data;
  _DataMsg(this.data);
}

class _ErrorMsg extends _ReadMsg {
  final String message;
  final int wsaError;
  _ErrorMsg(this.message, this.wsaError);
}

class _CloseMsg extends _ReadMsg {}

/// Parámetros que se pasan al isolate de lectura
class _ReaderArgs {
  final int socketHandle;
  final SendPort sendPort;
  _ReaderArgs(this.socketHandle, this.sendPort);
}

// ─── Isolate de lectura ───────────────────────────────────────────────────────
// Corre en su propio isolate para no bloquear el event loop de Dart.
// Usa recv() bloqueante (socket en modo bloqueante para simplificar).

void _readerIsolate(_ReaderArgs args) {
  final ws = Winsock.instance;
  final buf = calloc<Uint8>(_kReadBufferSize);

  try {
    while (true) {
      final n = ws.recv(args.socketHandle, buf, _kReadBufferSize, 0);

      if (n == 0) {
        // Conexión cerrada limpiamente por el peer
        args.sendPort.send(_CloseMsg());
        break;
      }

      if (n == SOCKET_ERROR) {
        final err = ws.getLastError();
        args.sendPort.send(_ErrorMsg('recv() failed', err));
        break;
      }

      // Copiar los bytes recibidos a un Uint8List independiente
      final data = Uint8List(n);
      for (var i = 0; i < n; i++) {
        data[i] = buf[i];
      }
      args.sendPort.send(_DataMsg(data));
    }
  } finally {
    calloc.free(buf);
  }
}

// ─── NativeWinUnixSocket ────────────────────────────────────────────────────────────

/// Canal bidireccional de bytes (Stream + StreamSink) sobre un Unix socket
/// nativo en Windows via Winsock2 FFI.
///
/// No implementa dart:io Socket — es un wrapper deliberadamente minimal
/// para conectar a gRPC via viaStreams() o cualquier protocolo custom.
///
/// Ejemplo de uso (cliente):
/// ```dart
/// final socket = await NativeWinUnixSocket.connect(r'\\.\pipe\mysock');
/// socket.stream.listen((data) => print('Recibido: $data'));
/// socket.sink.add(Uint8List.fromList([1, 2, 3]));
/// await socket.close();
/// ```
class NativeWinUnixSocket {
  final int _handle;
  final Winsock _ws;

  final StreamController<Uint8List> _incomingController;
  late final _WinUnixSink _sink;
  Isolate? _readerIsolate;

  NativeWinUnixSocket._(this._handle, this._ws)
      : _incomingController = StreamController<Uint8List>();

  /// Stream de bytes entrantes. Se cierra cuando la conexión se termina.
  Stream<Uint8List> get stream => _incomingController.stream;

  /// Sink para enviar bytes. Llamar a [close()] en el sink equivale a
  /// cerrar el canal completo.
  StreamSink<Uint8List> get sink => _sink;

  /// Conecta a un Unix socket existente en [path].
  ///
  /// En Windows el path tiene la forma: `C:\path\to\socket.sock`
  /// o usando el namespace de sockets: `\\.\pipe\...` NO — para AF_UNIX
  /// es un path de filesystem normal, ej: `C:\tmp\grpc.sock`
  static Future<NativeWinUnixSocket> connect(String path) async {
    final ws = Winsock.instance;

    final handle = ws.socket(AF_UNIX, SOCK_STREAM, 0);
    if (handle == INVALID_SOCKET) {
      throw SocketException._fromWsa(ws, 'socket() failed');
    }

    final addrPtr = calloc<SockaddrUn>();
    try {
      _fillSockaddr(addrPtr, path);
      final result = ws.connect(handle, addrPtr, sizeOf<SockaddrUn>());
      if (result == SOCKET_ERROR) {
        ws.closeSocket(handle);
        throw SocketException._fromWsa(ws, 'connect() failed to $path');
      }
    } finally {
      calloc.free(addrPtr);
    }

    final socket = NativeWinUnixSocket._(handle, ws);
    await socket._startReader();
    return socket;
  }

  /// Constructor interno — usado por [WinUnixServerSocket] cuando acepta
  /// una conexión entrante.
  static Future<NativeWinUnixSocket> fromHandle(int handle) async {
    final socket = NativeWinUnixSocket._(handle, Winsock.instance);
    await socket._startReader();
    return socket;
  }

  Future<void> _startReader() async {
    _sink = _WinUnixSink(_handle, _ws, _incomingController);

    final receivePort = ReceivePort();
    _readerIsolate = await Isolate.spawn(
      _readerIsolate_,
      _ReaderArgs(_handle, receivePort.sendPort),
      debugName: 'NativeWinUnixSocket.reader#$_handle',
    );

    receivePort.listen((msg) {
      switch (msg) {
        case _DataMsg(:final data):
          if (!_incomingController.isClosed) {
            _incomingController.add(data);
          }
        case _ErrorMsg(:final message, :final wsaError):
          if (!_incomingController.isClosed) {
            _incomingController.addError(
              SocketException('$message (WSA error: $wsaError)'),
            );
            _incomingController.close();
          }
          receivePort.close();
        case _CloseMsg():
          if (!_incomingController.isClosed) {
            _incomingController.close();
          }
          receivePort.close();
      }
    });
  }

  /// Cierra la conexión y libera recursos.
  Future<void> close() async {
    _ws.shutdown(_handle, SD_BOTH);
    _ws.closeSocket(_handle);
    _readerIsolate?.kill(priority: Isolate.immediate);
    if (!_incomingController.isClosed) {
      await _incomingController.close();
    }
  }
}

// Top-level wrapper para pasar al Isolate.spawn (no puede ser método de instancia)
void _readerIsolate_(_ReaderArgs args) => _readerIsolate(args);

// ─── Sink ─────────────────────────────────────────────────────────────────────

class _WinUnixSink implements StreamSink<Uint8List> {
  final int _handle;
  final Winsock _ws;
  final StreamController _owner;

  final Completer<void> _doneCompleter = Completer();

  _WinUnixSink(this._handle, this._ws, this._owner);

  @override
  Future get done => _doneCompleter.future;

  @override
  void add(Uint8List data) {
    if (data.isEmpty) return;
    _sendAll(data);
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) {
    // No hay forma de enviar un error por el socket; lo ignoramos
    // (el caller debería llamar a close() ante un error)
  }

  @override
  Future addStream(Stream<Uint8List> stream) async {
    await for (final chunk in stream) {
      add(chunk);
    }
  }

  @override
  Future close() async {
    _ws.shutdown(_handle, SD_BOTH);
    if (!_doneCompleter.isCompleted) _doneCompleter.complete();
    if (!_owner.isClosed) await _owner.close();
  }

  /// Envía todos los bytes garantizando que send() puede enviar parcialmente.
  void _sendAll(Uint8List data) {
    final buf = calloc<Uint8>(data.length);
    try {
      for (var i = 0; i < data.length; i++) {
        buf[i] = data[i];
      }

      var offset = 0;
      while (offset < data.length) {
        final n = _ws.send(_handle, buf + offset, data.length - offset, 0);
        if (n == SOCKET_ERROR) {
          final err = _ws.getLastError();
          throw SocketException('send() failed (WSA error: $err)');
        }
        offset += n;
      }
    } finally {
      calloc.free(buf);
    }
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

/// Rellena una estructura SockaddrUn con el path dado.
void _fillSockaddr(Pointer<SockaddrUn> ptr, String path) {
  ptr.ref.sunFamily = AF_UNIX;
  final bytes = path.codeUnits;
  if (bytes.length > 107) {
    throw ArgumentError('Unix socket path demasiado largo (máx 107 chars): $path');
  }
  for (var i = 0; i < bytes.length; i++) {
    ptr.ref.sunPath[i] = bytes[i];
  }
  ptr.ref.sunPath[bytes.length] = 0; // null terminator
}

// ─── Excepción ────────────────────────────────────────────────────────────────

class SocketException implements Exception {
  final String message;
  const SocketException(this.message);

  factory SocketException._fromWsa(Winsock ws, String prefix) {
    return SocketException('$prefix (WSA error: ${ws.getLastError()})');
  }

  @override
  String toString() => 'SocketException: $message';
}
