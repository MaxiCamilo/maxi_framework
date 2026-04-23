import 'dart:typed_data';

import 'package:maxi_framework/maxi_framework.dart';

import 'native_build_win_unix_socket_client.dart' if (dart.library.html) 'fake_win_unix_socket.dart';
import 'native_build_win_unix_socket_server.dart' if (dart.library.html) 'fake_win_unix_socket.dart';

String _replaceTempRoute(String path) {
  if (path.startsWith('/tmp/')) {
    return path.replaceFirst('/tmp/', '%TEMP%/');
  }

  return path;
}

abstract class WinUnixSocketClient with DisposableMixin, AsynchronouslyInitializedMixin implements Channel<Uint8List, Uint8List> {
  static Result<WinUnixSocketClient> buildClient(String path) {
    if (!appManager.isWindows) {
      return NegativeResult.controller(
        code: ErrorCode.implementationFailure,
        message: const FixedOration(message: 'WinUnixSocket is only implemented for Windows platforms'),
      );
    }

    return BuildWinUnixSocketClient(path: _replaceTempRoute(path)).execute();
  }
}

abstract class WinUnixSocketServer with DisposableMixin, AsynchronouslyInitializedMixin {
  List<Channel<Uint8List, Uint8List>> get clients;

  Stream<Channel<Uint8List, Uint8List>> get newClient;

  static Result<WinUnixSocketServer> buildServer(String path) {
    if (!appManager.isWindows) {
      return NegativeResult.controller(
        code: ErrorCode.implementationFailure,
        message: const FixedOration(message: 'WinUnixSocketServer is only implemented for Windows platforms'),
      );
    }

    return NativeBuildWinUnixSocketServer(path: _replaceTempRoute(path)).execute();
  }
}
