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

  bool get isConnected => _connectionState == AppConnectionState.connected;
  AppConnectionState get connectionState => _connectionState;
  String get serverAddress => _serverAddress;

  void _setState(AppConnectionState state) {
    if (_connectionState != state) {
      _connectionState = state;
      onConnectionStateChanged(_connectionState);
    }
  }

  Future<ConnectionResult> connect(String host, int port, {String? pin}) async {
    if (pin == null || pin.isEmpty) {
      return const ConnectionResult(
        success: false,
        error: ConnectionError.wrongPin,
        message: 'PIN kodu boş olamaz.',
      );
    }

    _reconnectTimer?.cancel();
    _reconnectTimer = null;

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
      final expectedFingerprint = prefs.getString(key);
      bool isCertMismatch = false;
      String? actualFingerprintCapture;

      final httpClient = HttpClient();
      httpClient.badCertificateCallback = (X509Certificate cert, String callbackHost, int callbackPort) {
        final bytes = cert.der;
        final actualFingerprint = sha256.convert(bytes).toString();

        if (expectedFingerprint == null) {
          prefs.setString(key, actualFingerprint);
          return true;
        } else if (expectedFingerprint == actualFingerprint) {
          return true;
        } else {
          isCertMismatch = true;
          actualFingerprintCapture = actualFingerprint;
          return false;
        }
      };

      WebSocket ws;
      try {
        ws = await WebSocket.connect(uri.toString(), customClient: httpClient).timeout(
          const Duration(seconds: 5),
          onTimeout: () => throw const SocketException('Connection timed out'),
        );
        ws.pingInterval = const Duration(seconds: 30);
      } on HandshakeException catch (_) {
        if (isCertMismatch) {
          _setState(AppConnectionState.certMismatch);
          return ConnectionResult(
            success: false,
            error: ConnectionError.certMismatch,
            message: 'Sertifika değişti! Olası MITM saldırısı veya cihaz formatlanmış olabilir.',
            newFingerprint: actualFingerprintCapture,
            mismatchHost: host,
          );
        }
        rethrow;
      }

      _channel = IOWebSocketChannel(ws);

      final authCompleter = Completer<ConnectionResult>();
      bool authResolved = false;

      _channel!.sink.add(jsonEncode({'auth': pin}));

      _channel!.stream.listen(
        (data) {
          try {
            final message = jsonDecode(data as String);
            if (message['type'] == 'auth') {
              if (message['status'] == 'fail') {
                debugPrint('Auth failed: wrong PIN');
                _setState(AppConnectionState.disconnected);
                _channel?.sink.close();
                if (!authResolved) {
                  authResolved = true;
                  onAuthResolved('PIN kodu yanlış.');
                  authCompleter.complete(
                    const ConnectionResult(
                      success: false,
                      error: ConnectionError.wrongPin,
                      message: 'PIN kodu yanlış.',
                    ),
                  );
                }
                return;
              }
              debugPrint('Auth successful');
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

  Future<void> disconnect() async {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _reconnectAttempts = _maxReconnectAttempts;
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
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'cert_fingerprint_$host';
    await prefs.setString(key, newFingerprint);
    debugPrint('Certificate fingerprint updated for $host (user-approved)');
    return connect(host, port, pin: pin);
  }
}
