import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

/// A TLS server socket whose handshakes time out, for [HttpServer.listenOn].
///
/// `HttpServer.bindSecure` waits for a client's TLS handshake forever: a
/// client that opens TCP connections and never sends its ClientHello holds a
/// file descriptor each, and enough of them leave the server unable to accept
/// the phone. The pending-auth limits of the server only start once the
/// handshake and the HTTP upgrade request are through. Here each handshake
/// gets [handshakeTimeout], and only [maxPerClient] (per [clientKey]) and
/// [maxTotal] may be under way at once; the rest are closed at once.
///
/// dart:io cannot cancel the handshake of a [SecureSocket], so it runs on a
/// [RawSecureSocket] and the result is wrapped in [_RawSocketAdapter].
class TlsHandshakeGate extends Stream<Socket> implements ServerSocket {
  TlsHandshakeGate._(
    this._server,
    this._context, {
    required this.handshakeTimeout,
    required this.maxPerClient,
    required this.maxTotal,
    required this.accepts,
    required this.clientKey,
  }) {
    _subscription = _server.listen(_onConnection, onError: _controller.addError, onDone: _controller.close);
  }

  static Future<TlsHandshakeGate> bind(
    InternetAddress address,
    int port,
    SecurityContext context, {
    Duration handshakeTimeout = const Duration(seconds: 10),
    int maxPerClient = 8,
    int maxTotal = 64,
    bool Function(InternetAddress remote) accepts = _acceptAll,
    required String Function(InternetAddress remote) clientKey,
  }) async {
    final server = await RawServerSocket.bind(address, port);
    return TlsHandshakeGate._(
      server,
      context,
      handshakeTimeout: handshakeTimeout,
      maxPerClient: maxPerClient,
      maxTotal: maxTotal,
      accepts: accepts,
      clientKey: clientKey,
    );
  }

  static bool _acceptAll(InternetAddress _) => true;

  final RawServerSocket _server;
  final SecurityContext _context;
  final Duration handshakeTimeout;
  final int maxPerClient;
  final int maxTotal;

  /// Connections from addresses it refuses are closed before the handshake.
  final bool Function(InternetAddress remote) accepts;

  /// The key handshakes are counted under (see `AuthManager.clientKey`).
  final String Function(InternetAddress remote) clientKey;

  final _controller = StreamController<Socket>();
  late final StreamSubscription<RawSocket> _subscription;
  final Map<String, int> _handshaking = {};
  int _handshakingTotal = 0;

  @visibleForTesting
  int get handshakesInProgress => _handshakingTotal;

  void _onConnection(RawSocket raw) {
    final InternetAddress remote;
    try {
      remote = raw.remoteAddress;
    } catch (_) {
      raw.close();
      return;
    }
    if (!accepts(remote)) {
      debugPrint('Refused connection from ${remote.address}: not on the local network');
      raw.close();
      return;
    }
    final key = clientKey(remote);
    final current = _handshaking[key] ?? 0;
    if (current >= maxPerClient || _handshakingTotal >= maxTotal) {
      debugPrint('Refused connection from $key: too many TLS handshakes under way');
      raw.close();
      return;
    }
    _handshaking[key] = current + 1;
    _handshakingTotal++;

    RawSecureSocket.secureServer(raw, _context).timeout(handshakeTimeout).then(
      (secure) {
        if (_controller.isClosed) {
          secure.close();
        } else {
          _controller.add(_RawSocketAdapter(secure));
        }
      },
      onError: (Object e) {
        // A timed-out handshake still holds the socket: closing it ends the
        // handshake (whose late error the timeout swallows).
        debugPrint('TLS handshake with $key failed: $e');
        raw.close();
      },
    ).whenComplete(() {
      final left = (_handshaking[key] ?? 1) - 1;
      if (left <= 0) {
        _handshaking.remove(key);
      } else {
        _handshaking[key] = left;
      }
      _handshakingTotal--;
    });
  }

  @override
  StreamSubscription<Socket> listen(
    void Function(Socket event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) =>
      _controller.stream.listen(onData, onError: onError, onDone: onDone, cancelOnError: cancelOnError);

  @override
  int get port => _server.port;

  @override
  InternetAddress get address => _server.address;

  @override
  Future<ServerSocket> close() async {
    await _server.close();
    await _subscription.cancel();
    // Not awaited: its future waits for a listener that may never come (or
    // that HttpServer.close already cancelled) to take the done event.
    unawaited(_controller.close());
    return this;
  }
}

/// A [Socket] over a connected [RawSecureSocket], with the read and write
/// handling dart:io's own socket has: one read per read event, writes
/// buffered until the socket takes them, and the send side shut down (TLS
/// close_notify) once everything is written after [close].
class _RawSocketAdapter extends Stream<Uint8List> implements Socket {
  _RawSocketAdapter(this._raw) {
    _controller = StreamController<Uint8List>(
      sync: true,
      onPause: () => _raw.readEventsEnabled = false,
      onResume: () => _raw.readEventsEnabled = true,
      onCancel: () {
        // The reader stopped listening: nothing more is wanted from the peer.
        if (!_readClosed) {
          _readClosed = true;
          _closeIfDone();
        }
      },
    );
    _raw.listen(_onEvent, onError: _onError, cancelOnError: true);
  }

  final RawSecureSocket _raw;
  late final StreamController<Uint8List> _controller;
  final _done = Completer<void>();

  final List<List<int>> _pending = [];
  int _offset = 0;
  final List<Completer<void>> _flushWaiters = [];
  bool _closing = false;
  bool _writeShutdown = false;
  bool _readClosed = false;
  bool _destroyed = false;

  @override
  Encoding encoding = utf8;

  void _onEvent(RawSocketEvent event) {
    switch (event) {
      case RawSocketEvent.read:
        if (_destroyed) return;
        final data = _raw.read();
        if (data != null && !_controller.isClosed) _controller.add(data);
      case RawSocketEvent.write:
        _flushWrites();
      case RawSocketEvent.readClosed:
        _readClosed = true;
        if (!_controller.isClosed) _controller.close();
        _closeIfDone();
      case RawSocketEvent.closed:
        _finish();
    }
  }

  void _onError(Object error, [StackTrace? stackTrace]) {
    if (!_controller.isClosed) {
      _controller.addError(error, stackTrace);
      _controller.close();
    }
    _finish(error, stackTrace);
  }

  /// Both directions are done: release the socket.
  void _closeIfDone() {
    if (_readClosed && _writeShutdown) _finish();
  }

  void _finish([Object? error, StackTrace? stackTrace]) {
    if (!_destroyed) {
      _destroyed = true;
      try {
        _raw.close();
      } catch (_) {}
    }
    if (!_controller.isClosed) _controller.close();
    _pending.clear();
    for (final waiter in _flushWaiters) {
      if (!waiter.isCompleted) waiter.complete();
    }
    _flushWaiters.clear();
    if (!_done.isCompleted) {
      if (error != null) {
        _done.completeError(error, stackTrace);
      } else {
        _done.complete();
      }
    }
  }

  void _flushWrites() {
    if (_destroyed) return;
    try {
      while (_pending.isNotEmpty) {
        final chunk = _pending.first;
        _offset += _raw.write(chunk, _offset);
        if (_offset < chunk.length) {
          _raw.writeEventsEnabled = true;
          return;
        }
        _pending.removeAt(0);
        _offset = 0;
      }
    } catch (e, st) {
      _onError(e, st);
      return;
    }
    for (final waiter in _flushWaiters) {
      waiter.complete();
    }
    _flushWaiters.clear();
    if (_closing && !_writeShutdown) {
      _writeShutdown = true;
      try {
        _raw.shutdown(SocketDirection.send);
      } catch (_) {}
      if (!_done.isCompleted) _done.complete();
      _closeIfDone();
    }
  }

  @override
  StreamSubscription<Uint8List> listen(
    void Function(Uint8List event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) =>
      _controller.stream.listen(onData, onError: onError, onDone: onDone, cancelOnError: cancelOnError);

  @override
  void add(List<int> data) {
    if (_closing) throw StateError('StreamSink is closed');
    if (_destroyed || data.isEmpty) return;
    _pending.add(data);
    _flushWrites();
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) => _finish(error, stackTrace);

  @override
  Future addStream(Stream<List<int>> stream) {
    final completer = Completer<void>();
    stream.listen(
      add,
      onError: (Object e, StackTrace st) {
        if (!completer.isCompleted) completer.completeError(e, st);
      },
      onDone: () {
        if (!completer.isCompleted) completer.complete();
      },
      cancelOnError: true,
    );
    return completer.future;
  }

  @override
  Future flush() {
    if (_pending.isEmpty || _destroyed) return Future.value();
    final waiter = Completer<void>();
    _flushWaiters.add(waiter);
    return waiter.future;
  }

  @override
  Future close() {
    if (!_closing) {
      _closing = true;
      _flushWrites();
    }
    return _done.future;
  }

  @override
  Future get done => _done.future;

  @override
  void destroy() => _finish();

  @override
  void write(Object? object) => add(encoding.encode('$object'));

  @override
  void writeAll(Iterable objects, [String separator = '']) => write(objects.join(separator));

  @override
  void writeln([Object? object = '']) => write('$object\n');

  @override
  void writeCharCode(int charCode) => write(String.fromCharCode(charCode));

  @override
  bool setOption(SocketOption option, bool enabled) => _raw.setOption(option, enabled);

  @override
  Uint8List getRawOption(RawSocketOption option) => _raw.getRawOption(option);

  @override
  void setRawOption(RawSocketOption option) => _raw.setRawOption(option);

  @override
  int get port => _raw.port;

  @override
  int get remotePort => _raw.remotePort;

  @override
  InternetAddress get address => _raw.address;

  @override
  InternetAddress get remoteAddress => _raw.remoteAddress;
}
