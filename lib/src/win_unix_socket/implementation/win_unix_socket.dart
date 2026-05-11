import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:path/path.dart' as p;

import 'named_pipe_ffi.dart';

const int _kReadBufferSize = 65536;
const int _kUint64Mask = 0xffffffffffffffff;

sealed class _ReadMsg {}

class _DataMsg extends _ReadMsg {
	final Uint8List data;

	_DataMsg(this.data);
}

class _ErrorMsg extends _ReadMsg {
	final String message;
	final int win32Error;

	_ErrorMsg(this.message, this.win32Error);
}

class _CloseMsg extends _ReadMsg {}

class _ReaderArgs {
	final int pipeHandle;
	final SendPort sendPort;

	_ReaderArgs(this.pipeHandle, this.sendPort);
}

void _readerIsolate(_ReaderArgs args) {
	final kernel = NamedPipeKernel.instance;
	final buffer = calloc<Uint8>(_kReadBufferSize);
	final bytesRead = calloc<Uint32>();

	try {
		while (true) {
			bytesRead.value = 0;
			final result = kernel.readFile(args.pipeHandle, buffer, _kReadBufferSize, bytesRead, nullptr);

			if (result == 0) {
				final error = kernel.getLastError();
				if (error == errorBrokenPipe || error == errorNoData) {
					args.sendPort.send(_CloseMsg());
				} else {
					args.sendPort.send(_ErrorMsg('ReadFile() failed', error));
				}
				break;
			}

			if (bytesRead.value == 0) {
				args.sendPort.send(_CloseMsg());
				break;
			}

			args.sendPort.send(_DataMsg(Uint8List.fromList(buffer.asTypedList(bytesRead.value))));
		}
	} finally {
		calloc.free(bytesRead);
		calloc.free(buffer);
	}
}

class NativeWinUnixSocket {
	final int _handle;
	final String _pipePath;
	final NamedPipeKernel _kernel;

	final StreamController<Uint8List> _incomingController;
	late final _WinUnixSink _sink;
	Isolate? _readerIsolate;

	NativeWinUnixSocket._(this._handle, this._pipePath, this._kernel) : _incomingController = StreamController<Uint8List>();

	Stream<Uint8List> get stream => _incomingController.stream;

	StreamSink<Uint8List> get sink => _sink;

	static Future<NativeWinUnixSocket> connect(String path) async {
		final kernel = NamedPipeKernel.instance;
		final pipePath = normalizeNamedPipePath(path);
		final handle = _openClientHandle(kernel, pipePath);

		final socket = NativeWinUnixSocket._(handle, pipePath, kernel);
		await socket._startReader();
		return socket;
	}

	static Future<NativeWinUnixSocket> fromHandle(int handle, {String? path}) async {
		final socket = NativeWinUnixSocket._(handle, path ?? '', NamedPipeKernel.instance);
		await socket._startReader();
		return socket;
	}

	Future<void> _startReader() async {
		_sink = _WinUnixSink(_handle, _kernel, _incomingController);

		final receivePort = ReceivePort();
		_readerIsolate = await Isolate.spawn(_readerIsolate_, _ReaderArgs(_handle, receivePort.sendPort), debugName: 'NativeWinUnixSocket.reader#$_handle');

		receivePort.listen((msg) {
			switch (msg) {
				case _DataMsg(:final data):
					if (!_incomingController.isClosed) {
						_incomingController.add(data);
					}
				case _ErrorMsg(:final message, :final win32Error):
					if (!_incomingController.isClosed) {
						_incomingController.addError(WinNamedPipeException('$message on $_pipePath (Win32 error: $win32Error)'));
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

	Future<void> close() async {
		_kernel.flushFileBuffers(_handle);
		_kernel.closeHandle(_handle);
		_readerIsolate?.kill(priority: Isolate.immediate);
		if (!_incomingController.isClosed) {
			await _incomingController.close();
		}
	}
}

void _readerIsolate_(_ReaderArgs args) => _readerIsolate(args);

class _WinUnixSink implements StreamSink<Uint8List> {
	final int _handle;
	final NamedPipeKernel _kernel;
	final StreamController<Uint8List> _owner;

	final Completer<void> _doneCompleter = Completer<void>();

	_WinUnixSink(this._handle, this._kernel, this._owner);

	@override
	Future<void> get done => _doneCompleter.future;

	@override
	void add(Uint8List data) {
		if (data.isEmpty) {
			return;
		}

		_writeAll(data);
	}

	@override
	void addError(Object error, [StackTrace? stackTrace]) {}

	@override
	Future<void> addStream(Stream<Uint8List> stream) async {
		await for (final chunk in stream) {
			add(chunk);
		}
	}

	@override
	Future<void> close() async {
		_kernel.flushFileBuffers(_handle);
		_kernel.closeHandle(_handle);
		if (!_doneCompleter.isCompleted) {
			_doneCompleter.complete();
		}
		if (!_owner.isClosed) {
			await _owner.close();
		}
	}

	void _writeAll(Uint8List data) {
		final buffer = calloc<Uint8>(data.length);
		final bytesWritten = calloc<Uint32>();

		try {
			buffer.asTypedList(data.length).setAll(0, data);

			var offset = 0;
			while (offset < data.length) {
				bytesWritten.value = 0;
				final result = _kernel.writeFile(_handle, buffer + offset, data.length - offset, bytesWritten, nullptr);
				if (result == 0) {
					throw WinNamedPipeException._fromWin32(_kernel, 'WriteFile() failed');
				}
				offset += bytesWritten.value;
			}
		} finally {
			calloc.free(bytesWritten);
			calloc.free(buffer);
		}
	}
}

String normalizeNamedPipePath(String path) {
	if (path.startsWith(r'\\.\pipe\')) {
		return path;
	}

	final normalized = path.replaceAll('\\', '/');
	final basename = p.basename(normalized);
	final safeBasename = basename.isEmpty ? 'channel' : basename.replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '_');
	final suffix = _hashPath(normalized);
	final trimmedBasename = safeBasename.substring(0, min(safeBasename.length, 32));

	return '${r'\\.\pipe\maxi_framework_'}${suffix}_$trimmedBasename';
}

int _openClientHandle(NamedPipeKernel kernel, String pipePath) {
	while (true) {
		final pipeName = pipePath.toNativeUtf16();
		try {
			final handle = kernel.createFile(pipeName, genericRead | genericWrite, 0, nullptr, openExisting, 0, 0);

			if (!kernel.isInvalidHandle(handle)) {
				return handle;
			}

			final error = kernel.getLastError();
			if (error != errorPipeBusy) {
				throw WinNamedPipeException('CreateFileW() failed on $pipePath (Win32 error: $error)');
			}
		} finally {
			calloc.free(pipeName);
		}

		final waitName = pipePath.toNativeUtf16();
		try {
			final waitResult = kernel.waitNamedPipe(waitName, nmpwaitWaitForever);
			if (waitResult == 0) {
				throw WinNamedPipeException._fromWin32(kernel, 'WaitNamedPipeW() failed for $pipePath');
			}
		} finally {
			calloc.free(waitName);
		}
	}
}

String _hashPath(String path) {
	var hash = 0xcbf29ce484222325;
	for (final byte in utf8.encode(path)) {
		hash ^= byte;
		hash = (hash * 0x100000001b3) & _kUint64Mask;
	}
	return hash.toRadixString(16).padLeft(16, '0');
}

class WinNamedPipeException implements Exception {
	final String message;

	const WinNamedPipeException(this.message);

	factory WinNamedPipeException._fromWin32(NamedPipeKernel kernel, String prefix) {
		return WinNamedPipeException('$prefix (Win32 error: ${kernel.getLastError()})');
	}

	factory WinNamedPipeException.fromWin32(NamedPipeKernel kernel, String prefix) {
		return WinNamedPipeException._fromWin32(kernel, prefix);
	}

	@override
	String toString() => 'WinNamedPipeException: $message';
}
