import 'dart:ffi';

import 'package:ffi/ffi.dart';

final DynamicLibrary _kernel32 = DynamicLibrary.open('kernel32.dll');

const int genericRead = 0x80000000;
const int genericWrite = 0x40000000;

const int openExisting = 3;

const int pipeAccessDuplex = 0x00000003;
const int pipeTypeByte = 0x00000000;
const int pipeReadModeByte = 0x00000000;
const int pipeWait = 0x00000000;
const int pipeRejectRemoteClients = 0x00000008;
const int pipeUnlimitedInstances = 255;

const int invalidHandleValue = -1;
const int nullHandleValue = 0;

const int errorBrokenPipe = 109;
const int errorInvalidHandle = 6;
const int errorNoData = 232;
const int errorPipeBusy = 231;
const int errorPipeConnected = 535;

const int nmpwaitWaitForever = 0xffffffff;

typedef _CreateNamedPipeNative = IntPtr Function(Pointer<Utf16> lpName, Uint32 dwOpenMode, Uint32 dwPipeMode, Uint32 nMaxInstances, Uint32 nOutBufferSize, Uint32 nInBufferSize, Uint32 nDefaultTimeOut, Pointer<Void> lpSecurityAttributes);

typedef _CreateNamedPipeDart = int Function(Pointer<Utf16> lpName, int dwOpenMode, int dwPipeMode, int nMaxInstances, int nOutBufferSize, int nInBufferSize, int nDefaultTimeOut, Pointer<Void> lpSecurityAttributes);

typedef _CreateFileNative = IntPtr Function(Pointer<Utf16> lpFileName, Uint32 dwDesiredAccess, Uint32 dwShareMode, Pointer<Void> lpSecurityAttributes, Uint32 dwCreationDisposition, Uint32 dwFlagsAndAttributes, IntPtr hTemplateFile);

typedef _CreateFileDart = int Function(Pointer<Utf16> lpFileName, int dwDesiredAccess, int dwShareMode, Pointer<Void> lpSecurityAttributes, int dwCreationDisposition, int dwFlagsAndAttributes, int hTemplateFile);

typedef _ConnectNamedPipeNative = Int32 Function(IntPtr hNamedPipe, Pointer<Void> lpOverlapped);

typedef _ConnectNamedPipeDart = int Function(int hNamedPipe, Pointer<Void> lpOverlapped);

typedef _DisconnectNamedPipeNative = Int32 Function(IntPtr hNamedPipe);
typedef _DisconnectNamedPipeDart = int Function(int hNamedPipe);

typedef _ReadFileNative = Int32 Function(IntPtr hFile, Pointer<Uint8> lpBuffer, Uint32 nNumberOfBytesToRead, Pointer<Uint32> lpNumberOfBytesRead, Pointer<Void> lpOverlapped);

typedef _ReadFileDart = int Function(int hFile, Pointer<Uint8> lpBuffer, int nNumberOfBytesToRead, Pointer<Uint32> lpNumberOfBytesRead, Pointer<Void> lpOverlapped);

typedef _WriteFileNative = Int32 Function(IntPtr hFile, Pointer<Uint8> lpBuffer, Uint32 nNumberOfBytesToWrite, Pointer<Uint32> lpNumberOfBytesWritten, Pointer<Void> lpOverlapped);

typedef _WriteFileDart = int Function(int hFile, Pointer<Uint8> lpBuffer, int nNumberOfBytesToWrite, Pointer<Uint32> lpNumberOfBytesWritten, Pointer<Void> lpOverlapped);

typedef _FlushFileBuffersNative = Int32 Function(IntPtr hFile);
typedef _FlushFileBuffersDart = int Function(int hFile);

typedef _CloseHandleNative = Int32 Function(IntPtr hObject);
typedef _CloseHandleDart = int Function(int hObject);

typedef _GetLastErrorNative = Uint32 Function();
typedef _GetLastErrorDart = int Function();

typedef _WaitNamedPipeNative = Int32 Function(Pointer<Utf16> lpNamedPipeName, Uint32 nTimeOut);

typedef _WaitNamedPipeDart = int Function(Pointer<Utf16> lpNamedPipeName, int nTimeOut);

final class NamedPipeKernel {
	NamedPipeKernel._()
		: _createNamedPipe = _kernel32.lookupFunction<_CreateNamedPipeNative, _CreateNamedPipeDart>('CreateNamedPipeW'),
			_createFile = _kernel32.lookupFunction<_CreateFileNative, _CreateFileDart>('CreateFileW'),
			_connectNamedPipe = _kernel32.lookupFunction<_ConnectNamedPipeNative, _ConnectNamedPipeDart>('ConnectNamedPipe'),
			_disconnectNamedPipe = _kernel32.lookupFunction<_DisconnectNamedPipeNative, _DisconnectNamedPipeDart>('DisconnectNamedPipe'),
			_readFile = _kernel32.lookupFunction<_ReadFileNative, _ReadFileDart>('ReadFile'),
			_writeFile = _kernel32.lookupFunction<_WriteFileNative, _WriteFileDart>('WriteFile'),
			_flushFileBuffers = _kernel32.lookupFunction<_FlushFileBuffersNative, _FlushFileBuffersDart>('FlushFileBuffers'),
			_closeHandle = _kernel32.lookupFunction<_CloseHandleNative, _CloseHandleDart>('CloseHandle'),
			_getLastError = _kernel32.lookupFunction<_GetLastErrorNative, _GetLastErrorDart>('GetLastError'),
			_waitNamedPipe = _kernel32.lookupFunction<_WaitNamedPipeNative, _WaitNamedPipeDart>('WaitNamedPipeW');

	static final NamedPipeKernel instance = NamedPipeKernel._();

	final _CreateNamedPipeDart _createNamedPipe;
	final _CreateFileDart _createFile;
	final _ConnectNamedPipeDart _connectNamedPipe;
	final _DisconnectNamedPipeDart _disconnectNamedPipe;
	final _ReadFileDart _readFile;
	final _WriteFileDart _writeFile;
	final _FlushFileBuffersDart _flushFileBuffers;
	final _CloseHandleDart _closeHandle;
	final _GetLastErrorDart _getLastError;
	final _WaitNamedPipeDart _waitNamedPipe;

	int createNamedPipe(Pointer<Utf16> name, int openMode, int pipeMode, int maxInstances, int outBufferSize, int inBufferSize, int defaultTimeout, Pointer<Void> securityAttributes) =>
			_createNamedPipe(name, openMode, pipeMode, maxInstances, outBufferSize, inBufferSize, defaultTimeout, securityAttributes);

	int createFile(Pointer<Utf16> fileName, int desiredAccess, int shareMode, Pointer<Void> securityAttributes, int creationDisposition, int flagsAndAttributes, int templateFile) =>
			_createFile(fileName, desiredAccess, shareMode, securityAttributes, creationDisposition, flagsAndAttributes, templateFile);

	int connectNamedPipe(int handle, Pointer<Void> overlapped) => _connectNamedPipe(handle, overlapped);

	int disconnectNamedPipe(int handle) => _disconnectNamedPipe(handle);

	int readFile(int handle, Pointer<Uint8> buffer, int bytesToRead, Pointer<Uint32> bytesRead, Pointer<Void> overlapped) => _readFile(handle, buffer, bytesToRead, bytesRead, overlapped);

	int writeFile(int handle, Pointer<Uint8> buffer, int bytesToWrite, Pointer<Uint32> bytesWritten, Pointer<Void> overlapped) => _writeFile(handle, buffer, bytesToWrite, bytesWritten, overlapped);

	int flushFileBuffers(int handle) => _flushFileBuffers(handle);

	int closeHandle(int handle) => _closeHandle(handle);

	int getLastError() => _getLastError();

	int waitNamedPipe(Pointer<Utf16> name, int timeout) => _waitNamedPipe(name, timeout);

	bool isInvalidHandle(int handle) => handle == invalidHandleValue;

	bool isNullHandle(int handle) => handle == nullHandleValue;
}
