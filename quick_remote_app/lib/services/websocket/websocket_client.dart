import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../websocket_service.dart' show AppConnectionState, ConnectionError, ConnectionResult;

class WebSocketClient {
  WebSocketChannel? _channel;
  StreamSubscription? _streamSubscription;
  AppConnectionState _connectionState = AppConnectionState.disconnected;
  String _serverAddress = '';
  Timer? _reconnectTimer;

  // Reconnect state
  String? _lastHost;
  int? _lastPort;
  String? _lastPin;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 10;
  static const Duration _reconnectDelay = Duration(seconds: 3);

  // Callbacks
  final void Function(AppConnectionState) onConnectionStateChanged;
  final void Function(Map<String, dynamic>) onMessage;
  final void Function(String?) onAuthResolved;

  WebSocketClient({
    required this.onConnectionStateChanged,
    required this.onMessage,
    required this.onAuthResolved,
  });

  /// Close code of a phone removed on the PC (`WebSocketServer.closedByPc`).
  static const closedByPc = 4005;

  bool get isConnected => _connectionState == AppConnectionState.connected;
  AppConnectionState get connectionState => _connectionState;
  String get serverAddress => _serverAddress;

  void _setState(AppConnectionState state) {
    if (_connectionState != state) {
      _connectionState = state;
      onConnectionStateChanged(_connectionState);
    }
  }

  Future<ConnectionResult> connect(String host, int port, {String? pin, String? expectedFingerprint}) async {
    if (pin == null || pin.isEmpty) {
      return const ConnectionResult(
        success: false,
        error: ConnectionError.wrongPin,
        message: 'PIN kodu boş olamaz.',
      );
    }

    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    await _streamSubscription?.cancel();
    _streamSubscription = null;
    await _channel?.sink.close();
    _channel = null;

    _setState(_reconnectAttempts > 0
        ? AppConnectionState.reconnecting
        : AppConnectionState.connecting);

    _serverAddress = '$host:$port';
    _lastHost = host;
    _lastPort = port;
    _lastPin = pin;

    try {
      String formattedHost = host;
      if (host.contains(':') && !host.startsWith('[')) {
        formattedHost = '[$host]';
      }
      final uri = Uri.parse('wss://$formattedHost:$port');
      final prefs = await SharedPreferences.getInstance();
      final key = 'cert_fingerprint_$host';
      // A fingerprint from the QR code comes straight from the PC screen, so it
      // takes precedence over whatever was pinned for this address before.
      final qrPinned = expectedFingerprint != null;
      final pinnedFingerprint = expectedFingerprint ?? prefs.getString(key);
      bool isCertMismatch = false;
      bool isUnverified = false;
      String? seenFingerprint;

      // No trusted roots: every certificate reaches the callback, so the pin is
      // enforced even for a certificate that a public CA would vouch for.
      final httpClient = HttpClient(context: SecurityContext(withTrustedRoots: false));
      httpClient.badCertificateCallback = (X509Certificate cert, String callbackHost, int callbackPort) {
        final actualFingerprint = sha256.convert(cert.der).toString();
        seenFingerprint = actualFingerprint;
        if (pinnedFingerprint == actualFingerprint) return true;
        // Nothing to check against: stop before the PIN goes out, so a fake
        // PC answering the mDNS query or the typed address never sees it.
        if (pinnedFingerprint == null) {
          isUnverified = true;
        } else {
          isCertMismatch = true;
        }
        return false;
      };

      WebSocket ws;
      try {
        ws = await WebSocket.connect(uri.toString(), customClient: httpClient).timeout(
          const Duration(seconds: 5),
          onTimeout: () => throw const SocketException('Connection timed out'),
        );
        ws.pingInterval = const Duration(seconds: 30);
      } on HandshakeException catch (_) {
        if (isUnverified) {
          _setState(AppConnectionState.disconnected);
          return ConnectionResult(
            success: false,
            error: ConnectionError.unverified,
            message: 'Bu PC ile ilk bağlantı: güvenlik kodunu karşılaştırın.',
            newFingerprint: seenFingerprint,
            mismatchHost: host,
          );
        }
        if (isCertMismatch) {
          _setState(AppConnectionState.certMismatch);
          if (qrPinned) {
            return ConnectionResult(
              success: false,
              error: ConnectionError.certRejected,
              message: 'PC\'nin sertifikası QR kodundakiyle eşleşmiyor. Bağlantı güvenli değil, '
                  'bağlanılmadı. QR kodunu yeniden tarayın.',
              mismatchHost: host,
            );
          }
          return ConnectionResult(
            success: false,
            error: ConnectionError.certMismatch,
            message: 'Sertifika değişti! Olası MITM saldırısı veya cihaz formatlanmış olabilir.',
            newFingerprint: seenFingerprint,
            mismatchHost: host,
          );
        }
        rethrow;
      } on WebSocketException catch (e) {
        if (e.httpStatusCode == HttpStatus.tooManyRequests) {
          _setState(AppConnectionState.disconnected);
          return const ConnectionResult(
            success: false,
            error: ConnectionError.rateLimited,
            message: 'Çok fazla hatalı deneme. Bir dakika sonra tekrar deneyin.',
          );
        }
        rethrow;
      }

      _channel = IOWebSocketChannel(ws);

      final authCompleter = Completer<ConnectionResult>();
      bool authResolved = false;

      _channel!.sink.add(jsonEncode({'auth': pin}));

      _streamSubscription = _channel!.stream.listen(
        (data) {
          try {
            final message = jsonDecode(data as String);
            if (message['type'] == 'auth') {
              if (message['status'] == 'fail') {
                final rateLimited = message['reason'] == 'rate_limited';
                debugPrint(rateLimited ? 'Auth refused: rate limited' : 'Auth failed: wrong PIN');
                _setState(AppConnectionState.disconnected);
                _channel?.sink.close();
                if (!authResolved) {
                  authResolved = true;
                  final text = rateLimited
                      ? 'Çok fazla hatalı deneme. Bir dakika sonra tekrar deneyin.'
                      : 'PIN kodu yanlış.';
                  onAuthResolved(text);
                  authCompleter.complete(
                    ConnectionResult(
                      success: false,
                      error: rateLimited ? ConnectionError.rateLimited : ConnectionError.wrongPin,
                      message: text,
                    ),
                  );
                }
                return;
              }
              debugPrint('Auth successful');
              // Trust on first use only after the PIN was accepted, so a failed
              // attempt against an impostor never pins the impostor's certificate.
              final fingerprint = seenFingerprint;
              if (fingerprint != null && prefs.getString(key) != fingerprint) {
                prefs.setString(key, fingerprint);
              }
              onMessage(message); // carries the PC's presenter/platform info
              _reconnectAttempts = 0;
              _setState(AppConnectionState.connected);
              if (!authResolved) {
                authResolved = true;
                onAuthResolved(null); // Success
                authCompleter.complete(const ConnectionResult.ok());
              }
              return;
            }

            onMessage(message);
          } catch (e) {
            debugPrint('Parse error: $e');
          }
        },
        onDone: () {
          final wasConnected = isConnected;
          debugPrint('WebSocket disconnected');
          if (ws.closeCode == closedByPc) {
            // The user removed this phone on the PC; the PIN changed too.
            _reconnectTimer?.cancel();
            onAuthResolved('PC bu cihazın bağlantısını kesti. Yeniden bağlanmak için QR kodu tekrar okutun.');
            _setState(AppConnectionState.failed);
            return;
          }
          if (!authResolved) {
            authResolved = true;
            onAuthResolved('Bağlantı beklenmedik şekilde kapandı.');
            authCompleter.complete(
              const ConnectionResult(
                success: false,
                error: ConnectionError.unknown,
                message: 'Bağlantı beklenmedik şekilde kapandı.',
              ),
            );
          }
          if (wasConnected) {
            _scheduleReconnect();
          } else {
            _setState(AppConnectionState.disconnected);
          }
        },
        onError: (error) {
          final wasConnected = isConnected;
          debugPrint('WebSocket error: $error');
          if (!authResolved) {
            authResolved = true;
            onAuthResolved('WebSocket hatası: $error');
            authCompleter.complete(
              ConnectionResult(
                success: false,
                error: ConnectionError.unknown,
                message: 'WebSocket hatası: $error',
              ),
            );
          }
          if (wasConnected) {
            _scheduleReconnect();
          } else {
            _setState(AppConnectionState.disconnected);
          }
        },
      );

      if (authResolved) {
        return const ConnectionResult.ok();
      }

      return await authCompleter.future.timeout(
        const Duration(seconds: 4),
        onTimeout: () {
          debugPrint('Auth response timeout');
          _setState(AppConnectionState.disconnected);
          _channel?.sink.close();
          return const ConnectionResult(
            success: false,
            error: ConnectionError.timeout,
            message: 'Kimlik doğrulama zaman aşımına uğradı.',
          );
        },
      );
    } on SocketException catch (e) {
      debugPrint('Connection failed (socket): $e');
      _setState(AppConnectionState.disconnected);
      return ConnectionResult(
        success: false,
        error: ConnectionError.serverNotFound,
        message: 'Sunucuya ulaşılamadı: ${e.message}',
      );
    } on TimeoutException catch (_) {
      debugPrint('Connection failed (timeout)');
      _setState(AppConnectionState.disconnected);
      return const ConnectionResult(
        success: false,
        error: ConnectionError.timeout,
        message: 'Bağlantı zaman aşımına uğradı.',
      );
    } catch (e) {
      debugPrint('Connection failed: $e');
      _setState(AppConnectionState.disconnected);
      return ConnectionResult(
        success: false,
        error: ConnectionError.unknown,
        message: 'Bilinmeyen hata: $e',
      );
    }
  }

  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      debugPrint('Max reconnect attempts reached');
      _setState(AppConnectionState.failed);
      return;
    }
    if (_lastHost == null || _lastPort == null) return;

    _reconnectTimer?.cancel();
    _reconnectAttempts++;
    debugPrint(
      'Scheduling reconnect attempt $_reconnectAttempts/$_maxReconnectAttempts',
    );

    _setState(AppConnectionState.reconnecting);

    _reconnectTimer = Timer(_reconnectDelay, () async {
      if (isConnected) return;
      debugPrint('Attempting reconnect...');
      final result = await connect(_lastHost!, _lastPort!, pin: _lastPin);
      if (!result.success && !isConnected) {
        if (result.error == ConnectionError.wrongPin ||
            result.error == ConnectionError.certMismatch ||
            result.error == ConnectionError.unverified ||
            result.error == ConnectionError.certRejected) {
          debugPrint('Fatal error (${result.error}), stopping reconnect loop');
          _setState(AppConnectionState.failed);
          return;
        }
        _scheduleReconnect();
      }
    });
  }

  void sendCommand(String command) {
    if (isConnected && _channel != null) {
      try {
        _channel!.sink.add(jsonEncode({'command': command}));
        debugPrint('Sent: $command');
      } catch (e) {
        debugPrint('Failed to send command: $e');
      }
    }
  }

  void sendTouchOrLaser(String type, double dx, double dy) {
    if (isConnected && _channel != null) {
      try {
        final bytes = ByteData(9);
        bytes.setUint8(0, type == 'TOUCH' ? 0 : 1);
        bytes.setFloat32(1, dx, Endian.little);
        bytes.setFloat32(5, dy, Endian.little);
        _channel!.sink.add(bytes.buffer.asUint8List());
      } catch (e) {
        debugPrint('Failed to send binary data: $e');
      }
    }
  }

  /// A connection the user starts gets the full set of reconnect attempts
  /// again; [disconnect] used them up so the closing socket does not retry.
  void resetReconnectAttempts() => _reconnectAttempts = 0;

  Future<void> disconnect() async {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _reconnectAttempts = _maxReconnectAttempts;
    _lastHost = null;
    _lastPort = null;
    _lastPin = null;
    await _streamSubscription?.cancel();
    _streamSubscription = null;
    await _channel?.sink.close();
    _channel = null;
    _setState(AppConnectionState.disconnected);
  }

  void manualReconnect() {
    if (_lastHost != null && _lastPort != null) {
      _reconnectAttempts = 0;
      connect(_lastHost!, _lastPort!, pin: _lastPin);
    }
  }

  Future<ConnectionResult> acceptCertificateAndReconnect(
    String host,
    String newFingerprint, {
    required int port,
    String? pin,
  }) {
    // Pin the approved certificate for this attempt only. The success path in
    // connect() stores it once the PIN is accepted, so a wrong PIN against an
    // impostor never makes the impostor's certificate permanent.
    return connect(host, port, pin: pin, expectedFingerprint: newFingerprint);
  }
}
