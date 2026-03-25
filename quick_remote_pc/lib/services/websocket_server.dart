import 'dart:io';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'input_simulator.dart';
import 'mouse_controller.dart';

/// WebSocket server that listens for commands from mobile/watch clients.
class WebSocketServer {
  HttpServer? _server;
  final List<WebSocket> _clients = [];
  final ValueNotifier<bool> isRunning = ValueNotifier(false);
  final ValueNotifier<int> clientCount = ValueNotifier(0);
  final ValueNotifier<String> lastCommand = ValueNotifier('');
  final ValueNotifier<bool> laserActive = ValueNotifier(false);
  final ValueNotifier<String> pin = ValueNotifier('');
  final MouseController mouseController = MouseController();
  final Set<WebSocket> _authenticatedClients = {};
  final Map<String, int> _failedAttempts = {};
  final Map<String, DateTime> _blockedIPs = {};
  static const int _maxFailedAttempts = 5;
  static const Duration _blockDuration = Duration(seconds: 60);
  int _port = 8090;

  /// Callback for laser position updates (for overlay).
  void Function(double x, double y)? onMouseMove;

  int get port => _port;

  /// Get the local IP address of this machine.
  /// Filters out virtual adapters (VMware, VirtualBox, etc.)
  Future<String> getLocalIP() async {
    final interfaces = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
      includeLinkLocal: false,
    );

    const virtualKeywords = [
      'vmware', 'virtualbox', 'vbox', 'hyper-v',
      'docker', 'wsl', 'vmnet', 'vethernet',
    ];

    String? fallbackIP;

    for (final interface in interfaces) {
      final nameLower = interface.name.toLowerCase();
      final isVirtual = virtualKeywords.any((kw) => nameLower.contains(kw));
      if (isVirtual) continue;

      for (final addr in interface.addresses) {
        if (!addr.isLoopback) {
          if (nameLower.contains('wi-fi') || nameLower.contains('wifi') ||
              nameLower.contains('wlan') || nameLower.contains('ethernet')) {
            return addr.address;
          }
          fallbackIP ??= addr.address;
        }
      }
    }
    return fallbackIP ?? '127.0.0.1';
  }

  /// Generate a random 4-digit PIN.
  String _generatePin() {
    final rng = Random.secure();
    return (1000 + rng.nextInt(9000)).toString();
  }

  /// Start the WebSocket server.
  Future<void> start({int port = 8090}) async {
    if (_server != null) return;

    _port = port;
    pin.value = _generatePin();
    try {
      _server = await HttpServer.bind(InternetAddress.anyIPv4, _port);
      isRunning.value = true;
      debugPrint('WebSocket server started on port $_port (PIN: ${pin.value})');

      _server!.listen(
        (HttpRequest request) async {
          if (WebSocketTransformer.isUpgradeRequest(request)) {
            // Check if IP is blocked due to brute-force
            final remoteIP = request.connectionInfo?.remoteAddress.address ?? '';
            if (_isIPBlocked(remoteIP)) {
              debugPrint('Blocked IP tried to connect: $remoteIP');
              request.response
                ..statusCode = HttpStatus.forbidden
                ..write('Too many failed attempts. Try again later.')
                ..close();
              return;
            }
            final ws = await WebSocketTransformer.upgrade(request);
            _handleClient(ws, remoteIP);
          } else {
            request.response
              ..statusCode = HttpStatus.ok
              ..write('QuickRemote PC Server is running')
              ..close();
          }
        },
        onError: (error) => debugPrint('Server error: $error'),
      );
    } catch (e) {
      debugPrint('Failed to start server: $e');
      isRunning.value = false;
    }
  }

  /// Check if an IP is currently blocked.
  bool _isIPBlocked(String ip) {
    final blockedUntil = _blockedIPs[ip];
    if (blockedUntil == null) return false;
    if (DateTime.now().isAfter(blockedUntil)) {
      _blockedIPs.remove(ip);
      _failedAttempts.remove(ip);
      return false;
    }
    return true;
  }

  void _handleClient(WebSocket ws, String remoteIP) {
    _clients.add(ws);
    clientCount.value = _clients.length;
    debugPrint('Client connected (awaiting auth). Total: ${_clients.length}');

    // Give the client 5 seconds to authenticate, otherwise disconnect
    Future.delayed(const Duration(seconds: 5), () {
      if (!_authenticatedClients.contains(ws)) {
        debugPrint('Client auth timeout – disconnecting');
        ws.close(4001, 'Auth timeout');
      }
    });

    ws.listen(
      (data) {
        try {
          final message = jsonDecode(data as String);

          // --- Authentication gate ---
          if (!_authenticatedClients.contains(ws)) {
            final authPin = message['auth'] as String?;
            if (authPin == pin.value) {
              _authenticatedClients.add(ws);
              ws.add(jsonEncode({'type': 'auth', 'status': 'ok'}));
              debugPrint('Client authenticated');
            } else {
              // Track failed attempt for brute-force protection
              _failedAttempts[remoteIP] = (_failedAttempts[remoteIP] ?? 0) + 1;
              if (_failedAttempts[remoteIP]! >= _maxFailedAttempts) {
                _blockedIPs[remoteIP] = DateTime.now().add(_blockDuration);
                debugPrint('IP blocked due to too many failed attempts: $remoteIP');
              }
              ws.add(jsonEncode({'type': 'auth', 'status': 'fail'}));
              debugPrint('Client auth failed (wrong PIN) from $remoteIP (attempt ${_failedAttempts[remoteIP]})');
              ws.close(4003, 'Invalid PIN');
            }
            return;
          }

          // Handle touch/gyro data (high-frequency, no logging)
          final type = message['type'] as String?;
          if (type == 'TOUCH' || type == 'GYRO') {
            final dx = (message['dx'] as num).toDouble();
            final dy = (message['dy'] as num).toDouble();
            mouseController.moveDelta(dx, dy);
            onMouseMove?.call(mouseController.currentX, mouseController.currentY);
            return;
          }

          // Handle regular commands
          final command = message['command'] as String?;
          if (command != null) {
            lastCommand.value = command;
            InputSimulator.executeCommand(command);
            debugPrint('Executed: $command');

            ws.add(jsonEncode({'type': 'ack', 'command': command}));
          }
        } catch (e) {
          debugPrint('Error processing message: $e');
        }
      },
      onDone: () {
        _clients.remove(ws);
        _authenticatedClients.remove(ws);
        clientCount.value = _clients.length;
        laserActive.value = false;
        debugPrint('Client disconnected. Total: ${_clients.length}');
      },
      onError: (error) {
        _clients.remove(ws);
        _authenticatedClients.remove(ws);
        clientCount.value = _clients.length;
        debugPrint('Client error: $error');
      },
    );
  }

  /// Stop the WebSocket server.
  Future<void> stop() async {
    for (final client in _clients) {
      await client.close();
    }
    _clients.clear();
    _authenticatedClients.clear();
    _failedAttempts.clear();
    _blockedIPs.clear();
    clientCount.value = 0;
    laserActive.value = false;
    pin.value = '';

    await _server?.close(force: true);
    _server = null;
    isRunning.value = false;
    debugPrint('Server stopped');
  }

  void broadcast(Map<String, dynamic> message) {
    final encoded = jsonEncode(message);
    for (final client in _authenticatedClients) {
      client.add(encoded);
    }
  }
}
