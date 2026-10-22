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
/// A finished handshake is not the end of it: dart:io's HttpServer times out
/// a connection that sends no request only after 120 s, and a request head
/// that never ends grows up to ~1 MB. So a connection must also complete its
/// request head (the blank line) within [requestTimeout] and [maxHeaderBytes],
/// and only [maxAwaitingPerClient] (per [clientKey]) and [maxAwaitingTotal]
/// may be waiting for it at once.
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
    required this.requestTimeout,
    required this.maxHeaderBytes,
    required this.maxAwaitingPerClient,
    required this.maxAwaitingTotal,
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
    Duration requestTimeout = const Duration(seconds: 10),
    int maxHeaderBytes = 16 * 1024,
    int maxAwaitingPerClient = 16,
    int maxAwaitingTotal = 128,
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
      requestTimeout: requestTimeout,
      maxHeaderBytes: maxHeaderBytes,
      maxAwaitingPerClient: maxAwaitingPerClient,
      maxAwaitingTotal: maxAwaitingTotal,
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

  /// How long a connection may take from the end of its handshake to the end
  /// of its first request head, and how large that head may be.
  final Duration requestTimeout;
  final int maxHeaderBytes;
  final int maxAwaitingPerClient;
  final int maxAwaitingTotal;

  /// Connections from addresses it refuses are closed before the handshake.
  final bool Function(InternetAddress remote) accepts;

  /// The key handshakes are counted under (see `AuthManager.clientKey`).
  final String Function(InternetAddress remote) clientKey;

  final _controller = StreamController<Socket>();
  late final StreamSubscription<RawSocket> _subscription;
  final Map<String, int> _handshaking = {};
  int _handshakingTotal = 0;
  final Map<String, int> _awaiting = {};
  int _awaitingTotal = 0;

  @visibleForTesting
  int get handshakesInProgress => _handshakingTotal;

  /// Connections through the handshake that have not sent a whole request
  /// head yet.
  @visibleForTesting
  int get awaitingRequest => _awaitingTotal;

  /// Takes a slot for a connection waiting for its request head; the returned
  /// function gives it back (once). Null when the limits are reached.
  void Function()? _awaitRequest(String key) {
    final current = _awaiting[key] ?? 0;
    if (current >= maxAwaitingPerClient || _awaitingTotal >= maxAwaitingTotal) return null;
    _awaiting[key] = current + 1;
    _awaitingTotal++;
    var released = false;
    return () {
      if (released) return;
      released = true;
      final left = (_awaiting[key] ?? 1) - 1;
      if (left <= 0) {
        _awaiting.remove(key);
      } else {
        _awaiting[key] = left;
      }
      _awaitingTotal--;
    };
  }

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
        final release = _controller.isClosed ? null : _awaitRequest(key);
        if (release == null) {
          if (!_controller.isClosed) debugPrint('Refused connection from $key: too many wait for their request');
          secure.close();
        } else {
          _controller.add(_RawSocketAdapter(
            secure,
            requestTimeout: requestTimeout,
            maxHeaderBytes: maxHeaderBytes,
            onRequestHead: release,
          ));
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
///
/// Until the first request head is complete (a blank line) it also enforces
/// the gate's [requestTimeout] and [maxHeaderBytes]; [onRequestHead] is
/// called once, when the head is complete or the socket is gone.
class _RawSocketAdapter extends Stream<Uint8List> implements Socket {
  _RawSocketAdapter(
    this._raw, {
    required Duration requestTimeout,
    required int maxHeaderBytes,
    required void Function() onRequestHead,
  })  : _maxHeaderBytes = maxHeaderBytes,
        _onRequestHead = onRequestHead {
    _headTimer = Timer(requestTimeout, () {
      if (!_headSeen) _finish();
    });
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
  final int _maxHeaderBytes;
  final void Function() _onRequestHead;
  Timer? _headTimer;
  bool _headSeen = false;
  int _headBytes = 0;
  int _lastBytes = 0; // the last four bytes seen, for the blank line
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
        if (data == null) return;
        if (!_headSeen && !_withinHead(data)) {
          _finish();
          return;
        }
        if (!_controller.isClosed) _controller.add(data);
      case RawSocketEvent.write:
        _flushWrites();
      case RawSocketEvent.readClosed:
        _readClosed = true;
        if (!_controller.isClosed) _controller.close();
        // The peer left before it finished its request: nothing to answer.
        if (!_headSeen) _finish();
        _closeIfDone();
      case RawSocketEvent.closed:
        _finish();
    }
  }

  /// Follows the bytes up to the blank line that ends the request head; false
  /// once the head is longer than [_maxHeaderBytes].
  bool _withinHead(Uint8List data) {
    for (final byte in data) {
      _headBytes++;
      _lastBytes = ((_lastBytes << 8) | byte) & 0xFFFFFFFF;
      if (_lastBytes == 0x0D0A0D0A || (_lastBytes & 0xFFFF) == 0x0A0A) {
        _endHead();
        return true;
      }
      if (_headBytes > _maxHeaderBytes) return false;
    }
    return true;
  }

  void _endHead() {
    if (_headSeen) return;
    _headSeen = true;
    _headTimer?.cancel();
    _onRequestHead();
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
    _endHead();
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
