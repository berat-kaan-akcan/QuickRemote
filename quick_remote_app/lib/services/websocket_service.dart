import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

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
  static const int _maxReconnectAttempts = 5;
  static const Duration _reconnectDelay = Duration(seconds: 3);

  bool get isConnected => _isConnected;
  String get serverAddress => _serverAddress;

  /// Connect to the PC companion app via WebSocket.
  /// Waits for auth response before reporting success.
  Future<bool> connect(String host, int port, {String? pin}) async {
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
        onTimeout: () => throw Exception('Connection timed out'),
      );

      // Use a Completer to wait for auth result before returning success.
      final authCompleter = Completer<bool>();
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
                  authCompleter.complete(false);
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
                authCompleter.complete(true);
              }
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
          notifyListeners();
          debugPrint('WebSocket disconnected');
          if (!authResolved) {
            authResolved = true;
            authCompleter.complete(false);
          }
          // Auto-reconnect if was previously connected
          if (wasConnected) {
            _scheduleReconnect();
          }
        },
        onError: (error) {
          final wasConnected = _isConnected;
          _isConnected = false;
          notifyListeners();
          debugPrint('WebSocket error: $error');
          if (!authResolved) {
            authResolved = true;
            authCompleter.complete(false);
          }
          // Auto-reconnect if was previously connected
          if (wasConnected) {
            _scheduleReconnect();
          }
        },
      );

      // If no PIN was sent, we're already connected
      if (authResolved) {
        return true;
      }

      // Wait for auth response with timeout
      return await authCompleter.future.timeout(
        const Duration(seconds: 6),
        onTimeout: () {
          debugPrint('Auth response timeout');
          _isConnected = false;
          notifyListeners();
          _channel?.sink.close();
          return false;
        },
      );
    } catch (e) {
      debugPrint('Connection failed: $e');
      _isConnected = false;
      notifyListeners();
      return false;
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
      await connect(_lastHost!, _lastPort!, pin: _lastPin);
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
