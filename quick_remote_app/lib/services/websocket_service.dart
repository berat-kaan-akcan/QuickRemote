import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Describes why a connection attempt failed.
enum ConnectionError {
  none,
  wrongPin,
  timeout,
  serverNotFound,
  unknown,
}

/// Result of a [WebSocketService.connect] call.
class ConnectionResult {
  final bool success;
  final ConnectionError error;
  final String? message;

  const ConnectionResult({
    required this.success,
    this.error = ConnectionError.none,
    this.message,
  });

  const ConnectionResult.ok()
      : success = true,
        error = ConnectionError.none,
        message = null;
}

/// WebSocket client service for connecting to PC companion app.
class WebSocketService extends ChangeNotifier {
  WebSocketChannel? _channel;
  bool _isConnected = false;
  String _serverAddress = '';
  Timer? _reconnectTimer;

  // Reconnect state
  String? _lastHost;
  int? _lastPort;
  String? _lastPin;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 10;
  static const Duration _reconnectDelay = Duration(seconds: 3);

  bool get isConnected => _isConnected;
  String get serverAddress => _serverAddress;

  // Slide state
  int _currentSlide = 0;
  int _totalSlides = 0;
  String _slideNotes = '';

  int get currentSlide => _currentSlide;
  int get totalSlides => _totalSlides;
  String get slideNotes => _slideNotes;

  /// Connect to the PC companion app via WebSocket.
  /// Waits for auth response before reporting success.
  Future<ConnectionResult> connect(String host, int port, {String? pin}) async {
    // Cancel any pending reconnect
    _reconnectTimer?.cancel();
    _reconnectTimer = null;

    _serverAddress = '$host:$port';
    _lastHost = host;
    _lastPort = port;
    _lastPin = pin;

    try {
      final uri = Uri.parse('ws://$host:$port');
      _channel = WebSocketChannel.connect(uri);
      await _channel!.ready.timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw const SocketException('Connection timed out'),
      );

      // Use a Completer to wait for auth result before returning success.
      final authCompleter = Completer<ConnectionResult>();
      bool authResolved = false;

      // Send PIN auth if provided
      if (pin != null && pin.isNotEmpty) {
        _channel!.sink.add(jsonEncode({'auth': pin}));
      } else {
        // No PIN required — consider connected immediately
        authResolved = true;
        _isConnected = true;
        _reconnectAttempts = 0;
        notifyListeners();
      }

      _channel!.stream.listen(
        (data) {
          try {
            final message = jsonDecode(data as String);
            // Handle auth response from server
            if (message['type'] == 'auth') {
              if (message['status'] == 'fail') {
                debugPrint('Auth failed: wrong PIN');
                _isConnected = false;
                notifyListeners();
                _channel?.sink.close();
                if (!authResolved) {
                  authResolved = true;
                  authCompleter.complete(const ConnectionResult(
                    success: false,
                    error: ConnectionError.wrongPin,
                    message: 'PIN kodu yanlış.',
                  ));
                }
                return;
              }
              // Auth successful
              debugPrint('Auth successful');
              _isConnected = true;
              _reconnectAttempts = 0;
              notifyListeners();
              if (!authResolved) {
                authResolved = true;
                authCompleter.complete(const ConnectionResult.ok());
              }
              return;
            }
            
            if (message['type'] == 'SLIDE_STATE') {
              _currentSlide = message['current'] as int? ?? 0;
              _totalSlides = message['total'] as int? ?? 0;
              _slideNotes = message['notes'] as String? ?? '';
              notifyListeners();
              return;
            }

            debugPrint('Server: $message');
          } catch (e) {
            debugPrint('Parse error: $e');
          }
        },
        onDone: () {
          final wasConnected = _isConnected;
          _isConnected = false;
          _currentSlide = 0;
          _totalSlides = 0;
          _slideNotes = '';
          notifyListeners();
          debugPrint('WebSocket disconnected');
          if (!authResolved) {
            authResolved = true;
            authCompleter.complete(const ConnectionResult(
              success: false,
              error: ConnectionError.unknown,
              message: 'Bağlantı beklenmedik şekilde kapandı.',
            ));
          }
          // Auto-reconnect if was previously connected
          if (wasConnected) {
            _scheduleReconnect();
          }
        },
        onError: (error) {
          final wasConnected = _isConnected;
          _isConnected = false;
          _currentSlide = 0;
          _totalSlides = 0;
          _slideNotes = '';
          notifyListeners();
          debugPrint('WebSocket error: $error');
          if (!authResolved) {
            authResolved = true;
            authCompleter.complete(ConnectionResult(
              success: false,
              error: ConnectionError.unknown,
              message: 'WebSocket hatası: $error',
            ));
          }
          // Auto-reconnect if was previously connected
          if (wasConnected) {
            _scheduleReconnect();
          }
        },
      );

      // If no PIN was sent, we're already connected
      if (authResolved) {
        return const ConnectionResult.ok();
      }

      // Wait for auth response with timeout
      return await authCompleter.future.timeout(
        const Duration(seconds: 6),
        onTimeout: () {
          debugPrint('Auth response timeout');
          _isConnected = false;
          notifyListeners();
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
      _isConnected = false;
      notifyListeners();
      return ConnectionResult(
        success: false,
        error: ConnectionError.serverNotFound,
        message: 'Sunucuya ulaşılamadı: ${e.message}',
      );
    } on TimeoutException catch (_) {
      debugPrint('Connection failed (timeout)');
      _isConnected = false;
      notifyListeners();
      return const ConnectionResult(
        success: false,
        error: ConnectionError.timeout,
        message: 'Bağlantı zaman aşımına uğradı.',
      );
    } catch (e) {
      debugPrint('Connection failed: $e');
      _isConnected = false;
      notifyListeners();
      return ConnectionResult(
        success: false,
        error: ConnectionError.unknown,
        message: 'Bilinmeyen hata: $e',
      );
    }
  }

  /// Schedule an automatic reconnect attempt.
  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      debugPrint('Max reconnect attempts reached');
      return;
    }
    if (_lastHost == null || _lastPort == null) return;

    _reconnectTimer?.cancel();
    _reconnectAttempts++;
    debugPrint('Scheduling reconnect attempt $_reconnectAttempts/$_maxReconnectAttempts');

    _reconnectTimer = Timer(_reconnectDelay, () async {
      if (_isConnected) return; // Already reconnected
      debugPrint('Attempting reconnect...');
      final result = await connect(_lastHost!, _lastPort!, pin: _lastPin);
      if (!result.success && !_isConnected) {
        _scheduleReconnect();
      }
    });
  }

  /// Send a command to the PC.
  void sendCommand(String command) {
    if (_isConnected && _channel != null) {
      _channel!.sink.add(jsonEncode({'command': command}));
      debugPrint('Sent: $command');
    }
  }

  /// Send raw JSON data to the PC (for gyroscope streaming).
  void sendRaw(Map<String, dynamic> data) {
    if (_isConnected && _channel != null) {
      _channel!.sink.add(jsonEncode(data));
    }
  }

  /// Disconnect from the server.
  Future<void> disconnect() async {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _reconnectAttempts = _maxReconnectAttempts; // Prevent auto-reconnect
    await _channel?.sink.close();
    _channel = null;
    _isConnected = false;
    notifyListeners();
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}
