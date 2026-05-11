import 'dart:async';
import 'dart:ffi';
import 'dart:isolate';

import 'package:ffi/ffi.dart';

import 'named_pipe_ffi.dart';
import 'win_unix_socket.dart';

const int _kPipeBufferSize = 65536;

class _AcceptArgs {
	final String pipePath;
	final SendPort sendPort;

	_AcceptArgs(this.pipePath, this.sendPort);
}

sealed class _AcceptMsg {}

class _NewConnectionMsg extends _AcceptMsg {
	final int clientHandle;
	final String pipePath;

	_NewConnectionMsg(this.clientHandle, this.pipePath);
}

class _ListenerHandleMsg extends _AcceptMsg {
	final int listenerHandle;

	_ListenerHandleMsg(this.listenerHandle);
}

class _AcceptErrorMsg extends _AcceptMsg {
	final String message;
	final int win32Error;

	_AcceptErrorMsg(this.message, this.win32Error);
}

class _AcceptStopMsg extends _AcceptMsg {}

void _acceptLoop(_AcceptArgs args) {
	final kernel = NamedPipeKernel.instance;
	var listeningHandle = _createServerPipeHandle(kernel, args.pipePath);
	args.sendPort.send(_ListenerHandleMsg(listeningHandle));

	while (true) {
		final result = kernel.connectNamedPipe(listeningHandle, nullptr);
		if (result == 0) {
			final error = kernel.getLastError();
			if (error != errorPipeConnected) {
				if (error == errorInvalidHandle || error == errorBrokenPipe || error == errorNoData) {
					args.sendPort.send(_AcceptStopMsg());
				} else {
					args.sendPort.send(_AcceptErrorMsg('ConnectNamedPipe() failed', error));
				}
				break;
			}
		}

		int? nextHandle;
		try {
			nextHandle = _createServerPipeHandle(kernel, args.pipePath);
			args.sendPort.send(_ListenerHandleMsg(nextHandle));
		} on WinNamedPipeException catch (ex) {
			args.sendPort.send(_NewConnectionMsg(listeningHandle, args.pipePath));
			args.sendPort.send(_AcceptErrorMsg(ex.message, kernel.getLastError()));
			break;
		}

		args.sendPort.send(_NewConnectionMsg(listeningHandle, args.pipePath));
		listeningHandle = nextHandle;
	}
}

class WinUnixServerSocket {
	final String path;
	final String _pipePath;
	final NamedPipeKernel _kernel;

	final StreamController<NativeWinUnixSocket> _connectionsController;
	Isolate? _acceptIsolate;
	ReceivePort? _receivePort;
	int? _listenerHandle;

	WinUnixServerSocket._(this.path, this._pipePath, this._kernel) : _connectionsController = StreamController<NativeWinUnixSocket>();

	Stream<NativeWinUnixSocket> get connections => _connectionsController.stream;

	static Future<WinUnixServerSocket> bind(String path, {int backlog = 128, bool deleteOnBind = true}) async {
		final kernel = NamedPipeKernel.instance;
		final pipePath = normalizeNamedPipePath(path);
		final server = WinUnixServerSocket._(path, pipePath, kernel);
		await server._startAcceptLoop();
		return server;
	}

	Future<void> _startAcceptLoop() async {
		final receivePort = ReceivePort();
		_receivePort = receivePort;

		_acceptIsolate = await Isolate.spawn(_acceptLoop, _AcceptArgs(_pipePath, receivePort.sendPort), debugName: 'WinUnixServerSocket.accept#$_pipePath');

		receivePort.listen((msg) async {
			switch (msg) {
				case _ListenerHandleMsg(:final listenerHandle):
					_listenerHandle = listenerHandle;
				case _NewConnectionMsg(:final clientHandle, :final pipePath):
					try {
						final client = await NativeWinUnixSocket.fromHandle(clientHandle, path: pipePath);
						if (!_connectionsController.isClosed) {
							_connectionsController.add(client);
						}
					} catch (ex, st) {
						if (!_connectionsController.isClosed) {
							_connectionsController.addError(ex, st);
						}
					}
				case _AcceptErrorMsg(:final message, :final win32Error):
					if (!_connectionsController.isClosed) {
						_connectionsController.addError(WinNamedPipeException('$message on $_pipePath (Win32 error: $win32Error)'));
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

	Future<void> close() async {
		final handle = _listenerHandle;
		if (handle != null && !_kernel.isInvalidHandle(handle) && !_kernel.isNullHandle(handle)) {
			_kernel.closeHandle(handle);
			_listenerHandle = null;
		}

		_acceptIsolate?.kill(priority: Isolate.immediate);
		_receivePort?.close();

		if (!_connectionsController.isClosed) {
			await _connectionsController.close();
		}
	}
}

int _createServerPipeHandle(NamedPipeKernel kernel, String pipePath) {
	final pipeName = pipePath.toNativeUtf16();
	try {
		final handle = kernel.createNamedPipe(pipeName, pipeAccessDuplex, pipeTypeByte | pipeReadModeByte | pipeWait | pipeRejectRemoteClients, pipeUnlimitedInstances, _kPipeBufferSize, _kPipeBufferSize, 0, nullptr);

		if (kernel.isInvalidHandle(handle)) {
			throw WinNamedPipeException.fromWin32(kernel, 'CreateNamedPipeW() failed for $pipePath');
		}

		return handle;
	} finally {
		calloc.free(pipeName);
	}
}
