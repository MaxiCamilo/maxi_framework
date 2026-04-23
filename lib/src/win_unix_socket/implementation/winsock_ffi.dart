// ignore_for_file: non_constant_identifier_names, camel_case_types

import 'dart:ffi';
import 'package:ffi/ffi.dart';

// ─── Tipos nativos ────────────────────────────────────────────────────────────

typedef SOCKET = IntPtr; // En Windows, SOCKET es UINT_PTR (size_t)
typedef HANDLE = Pointer<Void>;

const int INVALID_SOCKET = -1;
const int SOCKET_ERROR = -1;

// address families
const int AF_UNIX = 1;

// socket types
const int SOCK_STREAM = 1;

// shutdown
const int SD_BOTH = 2;

// WSA error codes
const int WSAEWOULDBLOCK = 10035;
const int WSAECONNRESET = 10054;
const int WSAENOTCONN = 10057;

// setsockopt / ioctlsocket
const int SOL_SOCKET = 0xFFFF;
const int SO_REUSEADDR = 0x0004;
const int FIONBIO = 0x8004667E; // set non-blocking

// ─── Estructuras ─────────────────────────────────────────────────────────────

/// sockaddr_un — misma estructura que en Linux (familia 1 byte + 108 bytes path)
final class SockaddrUn extends Struct {
  @Uint16()
  external int sunFamily;

  /// Path en UTF-8/ASCII, null-terminated, máx 107 chars útiles
  @Array(108)
  external Array<Uint8> sunPath;
}

/// WSAData — necesario para WSAStartup
final class WSAData extends Struct {
  @Uint16()
  external int wVersion;
  @Uint16()
  external int wHighVersion;
  @Uint16()
  external int iMaxSockets;
  @Uint16()
  external int iMaxUdpDg;
  external Pointer<Utf8> lpVendorInfo;
  @Array(257)
  external Array<Uint8> szDescription;
  @Array(129)
  external Array<Uint8> szSystemStatus;
}

// ─── Typedefs FFI ─────────────────────────────────────────────────────────────

// int WSAStartup(WORD wVersionRequired, LPWSADATA lpWSAData)
typedef WSAStartupNative = Int32 Function(Uint16 version, Pointer<WSAData> data);
typedef WSAStartupDart = int Function(int version, Pointer<WSAData> data);

// int WSACleanup()
typedef WSACleanupNative = Int32 Function();
typedef WSACleanupDart = int Function();

// int WSAGetLastError()
typedef WSAGetLastErrorNative = Int32 Function();
typedef WSAGetLastErrorDart = int Function();

// SOCKET socket(int af, int type, int protocol)
typedef SocketNative = IntPtr Function(Int32 af, Int32 type, Int32 protocol);
typedef SocketDart = int Function(int af, int type, int protocol);

// int bind(SOCKET s, const sockaddr* name, int namelen)
typedef BindNative = Int32 Function(IntPtr s, Pointer<SockaddrUn> addr, Int32 len);
typedef BindDart = int Function(int s, Pointer<SockaddrUn> addr, int len);

// int listen(SOCKET s, int backlog)
typedef ListenNative = Int32 Function(IntPtr s, Int32 backlog);
typedef ListenDart = int Function(int s, int backlog);

// SOCKET accept(SOCKET s, sockaddr* addr, int* addrlen)
typedef AcceptNative = IntPtr Function(IntPtr s, Pointer<SockaddrUn> addr, Pointer<Int32> addrlen);
typedef AcceptDart = int Function(int s, Pointer<SockaddrUn> addr, Pointer<Int32> addrlen);

// int connect(SOCKET s, const sockaddr* name, int namelen)
typedef ConnectNative = Int32 Function(IntPtr s, Pointer<SockaddrUn> addr, Int32 len);
typedef ConnectDart = int Function(int s, Pointer<SockaddrUn> addr, int len);

// int send(SOCKET s, const char* buf, int len, int flags)
typedef SendNative = Int32 Function(IntPtr s, Pointer<Uint8> buf, Int32 len, Int32 flags);
typedef SendDart = int Function(int s, Pointer<Uint8> buf, int len, int flags);

// int recv(SOCKET s, char* buf, int len, int flags)
typedef RecvNative = Int32 Function(IntPtr s, Pointer<Uint8> buf, Int32 len, Int32 flags);
typedef RecvDart = int Function(int s, Pointer<Uint8> buf, int len, int flags);

// int closesocket(SOCKET s)
typedef CloseSocketNative = Int32 Function(IntPtr s);
typedef CloseSocketDart = int Function(int s);

// int shutdown(SOCKET s, int how)
typedef ShutdownNative = Int32 Function(IntPtr s, Int32 how);
typedef ShutdownDart = int Function(int s, int how);

// int setsockopt(SOCKET s, int level, int optname, const char* optval, int optlen)
typedef SetsockoptNative = Int32 Function(IntPtr s, Int32 level, Int32 optname, Pointer<Int32> optval, Int32 optlen);
typedef SetsockoptDart = int Function(int s, int level, int optname, Pointer<Int32> optval, int optlen);

// int ioctlsocket(SOCKET s, long cmd, u_long* argp)
typedef IoctlsocketNative = Int32 Function(IntPtr s, Int32 cmd, Pointer<Uint32> argp);
typedef IoctlsocketDart = int Function(int s, int cmd, Pointer<Uint32> argp);

// ─── Loader ───────────────────────────────────────────────────────────────────

class Winsock {
  static Winsock? _instance;
  static Winsock get instance => _instance ??= Winsock._load();

  final DynamicLibrary _lib;

  late final WSAStartupDart wsaStartup;
  late final WSACleanupDart wsaCleanup;
  late final WSAGetLastErrorDart wsaGetLastError;
  late final SocketDart socket;
  late final BindDart bind;
  late final ListenDart listen;
  late final AcceptDart accept;
  late final ConnectDart connect;
  late final SendDart send;
  late final RecvDart recv;
  late final CloseSocketDart closeSocket;
  late final ShutdownDart shutdown;
  late final SetsockoptDart setsockopt;
  late final IoctlsocketDart ioctlsocket;

  Winsock._load() : _lib = DynamicLibrary.open('ws2_32.dll') {
    wsaStartup   = _lib.lookupFunction<WSAStartupNative,   WSAStartupDart>  ('WSAStartup');
    wsaCleanup   = _lib.lookupFunction<WSACleanupNative,   WSACleanupDart>  ('WSACleanup');
    wsaGetLastError = _lib.lookupFunction<WSAGetLastErrorNative, WSAGetLastErrorDart>('WSAGetLastError');
    socket       = _lib.lookupFunction<SocketNative,       SocketDart>      ('socket');
    bind         = _lib.lookupFunction<BindNative,         BindDart>        ('bind');
    listen       = _lib.lookupFunction<ListenNative,       ListenDart>      ('listen');
    accept       = _lib.lookupFunction<AcceptNative,       AcceptDart>      ('accept');
    connect      = _lib.lookupFunction<ConnectNative,      ConnectDart>     ('connect');
    send         = _lib.lookupFunction<SendNative,         SendDart>        ('send');
    recv         = _lib.lookupFunction<RecvNative,         RecvDart>        ('recv');
    closeSocket  = _lib.lookupFunction<CloseSocketNative,  CloseSocketDart> ('closesocket');
    shutdown     = _lib.lookupFunction<ShutdownNative,     ShutdownDart>    ('shutdown');
    setsockopt   = _lib.lookupFunction<SetsockoptNative,   SetsockoptDart>  ('setsockopt');
    ioctlsocket  = _lib.lookupFunction<IoctlsocketNative,  IoctlsocketDart> ('ioctlsocket');

    // Inicializar Winsock (versión 2.2)
    final wsaData = calloc<WSAData>();
    try {
      final result = wsaStartup(0x0202, wsaData); // MAKEWORD(2, 2)
      if (result != 0) throw StateError('WSAStartup failed: $result');
    } finally {
      calloc.free(wsaData);
    }
  }

  int getLastError() => wsaGetLastError();

  void dispose() {
    wsaCleanup();
    _instance = null;
  }
}
