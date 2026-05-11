@Timeout(Duration(seconds: 30))
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_framework/src/win_unix_socket.dart';
import 'package:test/test.dart';

T _expectResultOk<T>(Result<T> result, {String? context}) {
  expect(result.itsCorrect, isTrue, reason: context == null ? result.error.toString() : '$context: ${result.error}');
  return result.content;
}

void main() {
  test('WinUnixSocket performs a basic server client roundtrip on Windows', () async {
    final route = '/tmp/maxi_framework_named_pipe_smoke_${DateTime.now().microsecondsSinceEpoch}.sock';

    final server = _expectResultOk(WinUnixSocketServer.buildServer(route), context: 'server build failed');
    addTearDown(server.dispose);

    final acceptedClientFuture = server.newClient.first.timeout(const Duration(seconds: 10));

    final client = _expectResultOk(WinUnixSocketClient.buildClient(route), context: 'client build failed');
    addTearDown(client.dispose);

    final clientReceiver = _expectResultOk(client.getReceiver(), context: 'client receiver failed');

    final acceptedClient = await acceptedClientFuture;
    addTearDown(acceptedClient.dispose);

    final serverReceiver = _expectResultOk(acceptedClient.getReceiver(), context: 'server receiver failed');

    final serverToClient = Uint8List.fromList([1, 2, 3, 4]);
    final clientToServer = Uint8List.fromList([5, 6, 7, 8]);

    final clientIncomingFuture = clientReceiver.first.timeout(const Duration(seconds: 10));
    expect(acceptedClient.sendItem(serverToClient).itsCorrect, isTrue, reason: 'server failed to send the first payload');
    expect(await clientIncomingFuture, orderedEquals(serverToClient));

    final serverIncomingFuture = serverReceiver.first.timeout(const Duration(seconds: 10));
    final clientSendResult = client.sendItem(clientToServer);
    expect(clientSendResult.itsCorrect, isTrue, reason: 'client failed to send the second payload: ${clientSendResult.error}');
    expect(await serverIncomingFuture, orderedEquals(clientToServer));
  }, skip: !Platform.isWindows);
}
