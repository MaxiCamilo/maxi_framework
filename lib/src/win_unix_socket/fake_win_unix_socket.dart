import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_framework/src/win_unix_socket/win_unix_socket.dart';

class BuildWinUnixSocketClient implements SyncFunctionality<WinUnixSocketClient> {
  final String path;

  const BuildWinUnixSocketClient({required this.path});

  @override
  Result<WinUnixSocketClient> execute() {
    return NegativeResult.controller(
      code: ErrorCode.implementationFailure,
      message: const FixedOration(message: 'WinUnixSocketClient is only implemented for Windows platforms'),
    );
  }
}

class NativeBuildWinUnixSocketServer implements SyncFunctionality<WinUnixSocketServer> {
  final String path;

  const NativeBuildWinUnixSocketServer({required this.path});

  @override
  Result<WinUnixSocketServer> execute() {
    return NegativeResult.controller(
      code: ErrorCode.implementationFailure,
      message: const FixedOration(message: 'WinUnixSocketServer is only implemented for Windows platforms'),
    );
  }
}
