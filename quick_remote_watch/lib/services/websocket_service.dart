import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// WebSocket client service for connecting to PC companion app.
class WebSocketService extends ChangeNotifier {
  WebSocketChannel? _channel;
  bool _isConnected = false;
  String _serverAddress = '';

  bool get isConnected => _isConnected;
  String get serverAddress => _serverAddress;

  /// Connect to the PC companion app via WebSocket.
  /// Sends [pin] as the first message for authentication.
  Future<bool> connect(String host, int port, {String? pin}) async {
    _serverAddress = '$host:$port';
    try {
      final uri = Uri.parse('ws://$host:$port');
      _channel = WebSocketChannel.connect(uri);
      await _channel!.ready.timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw Exception('Connection timed out'),
      );

      _isConnected = true;
      notifyListeners();

      // Send PIN auth if provided
      if (pin != null && pin.isNotEmpty) {
        _channel!.sink.add(jsonEncode({'auth': pin}));
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
                return;
              }
              debugPrint('Auth successful');
              return;
            }
            debugPrint('Server: $message');
          } catch (e) {
            debugPrint('Parse error: $e');
          }
        },
        onDone: () {
          _isConnected = false;
          notifyListeners();
          debugPrint('WebSocket disconnected');
        },
        onError: (error) {
          _isConnected = false;
          notifyListeners();
          debugPrint('WebSocket error: $error');
        },
      );

      return true;
    } catch (e) {
      debugPrint('Connection failed: $e');
      _isConnected = false;
      notifyListeners();
      return false;
    }
  }

  /// Send a command to the PC.
  void sendCommand(String command) {
    if (_isConnected && _channel != null) {
      _channel!.sink.add(jsonEncode({'command': command}));
      debugPrint('Sent: $command');
    }
  }

  /// Disconnect from the server.
  Future<void> disconnect() async {
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
