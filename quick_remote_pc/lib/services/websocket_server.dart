import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:nsd/nsd.dart' as nsd;
import 'input_simulator.dart';
import 'mouse_controller.dart';
import 'package:quick_remote_shared/quick_remote_shared.dart';

import 'server/auth_manager.dart';
import 'server/network/avahi_publisher.dart';
import 'server/network_manager.dart';
import 'server/state_broadcaster.dart';

/// WebSocket server that listens for commands from mobile clients.
class WebSocketServer {
  HttpServer? _server;
  final List<WebSocket> _clients = [];
  final ValueNotifier<bool> isRunning = ValueNotifier(false);
  final ValueNotifier<int> clientCount = ValueNotifier(0);
  final ValueNotifier<String> lastCommand = ValueNotifier('');
  final ValueNotifier<bool> laserActive = ValueNotifier(false);
  final ValueNotifier<String> pin = ValueNotifier('');
  final ValueNotifier<String> localIP = ValueNotifier('');
  final ValueNotifier<bool> isPublicNetwork = ValueNotifier(false);
  /// Why the last start() failed (null when it succeeded).
  final ValueNotifier<String?> startError = ValueNotifier(null);
  /// Whether the mDNS advertisement succeeded (auto-discovery on the phone).
  final ValueNotifier<bool> mdnsAvailable = ValueNotifier(true);

  final MouseController mouseController = MouseController();
  final Set<WebSocket> _authenticatedClients = {};
  
  final AuthManager _authManager = AuthManager();
  late final StateBroadcaster _stateBroadcaster;
  
  int _port = 8090;
  nsd.Registration? _nsdRegistration;
  final AvahiPublisher _avahi = AvahiPublisher();
  
  final Map<WebSocket, Timer> _authTimers = {};
  final Map<WebSocket, int> _invalidMessageCount = {};
  final Map<WebSocket, int> _lastBinaryPacketTime = {};
  
  Timer? _networkCheckTimer;
  int _networkProfileTick = 0;

  /// Callback for laser position updates (for overlay).
  void Function(double x, double y)? onMouseMove;

  int get port => _port;

  WebSocketServer() {
    _stateBroadcaster = StateBroadcaster(
      onBroadcast: broadcast,
      hasClients: () => _authenticatedClients.isNotEmpty,
    );
  }

  Future<String> getLocalIP({bool force = false}) async {
    final ip = await NetworkManager.getLocalIP(force: force);
    if (localIP.value != ip) {
      localIP.value = ip;
    }
    return ip;
  }

  Future<void> start({int port = 8090}) async {
    if (_server != null) return;

    startError.value = null;
    pin.value = _authManager.generatePin();

    isPublicNetwork.value = await NetworkManager.checkNetworkProfile();
    _startNetworkMonitor();

    try {
      final ctx = await NetworkManager.loadOrGenerateCert();

      const maxRetries = 10;
      for (var i = 0; i < maxRetries; i++) {
        try {
          _port = port + i;
          _server = await HttpServer.bindSecure(InternetAddress.anyIPv6, _port, ctx);
          break;
        } on SocketException catch (e) {
          debugPrint('Port $_port is in use, trying next port... ($e)');
          if (i == maxRetries - 1) {
            throw SocketException(
              'Could not find a free port in range $port-${port + maxRetries - 1}',
            );
          }
        }
      }

      isRunning.value = true;
      debugPrint('WebSocket server started on port $_port (PIN: ${pin.value})');

      final hostname = Platform.localHostname;
      if (Platform.isLinux) {
        mdnsAvailable.value = await _avahi.register(
          name: hostname,
          type: '_quickremote._tcp',
          port: _port,
        );
      } else if (_nsdRegistration == null) {
        try {
          _nsdRegistration = await nsd.register(nsd.Service(
            name: hostname,
            type: '_quickremote._tcp',
            port: _port,
          ));
          debugPrint('mDNS Service registered as $hostname');
        } catch (e) {
          debugPrint('Failed to register mDNS service: $e');
        }
      }

      _stateBroadcaster.startSlideStatePoller();

      InputSimulator.onCommandError = (detail) {
        broadcast({
          'type': 'STATUS',
          'state': 'COMMAND_FAILED',
          'detail': detail,
        });
      };

      _server!.listen(
        (HttpRequest request) async {
          if (WebSocketTransformer.isUpgradeRequest(request)) {
            final remoteIP = request.connectionInfo?.remoteAddress.address ?? '';
            if (_authManager.isIPBlocked(remoteIP)) {
              debugPrint('Blocked IP tried to connect: $remoteIP');
              request.response
                ..statusCode = HttpStatus.forbidden
                ..write('Too many failed attempts. Try again later.')
                ..close();
              return;
            }
            final ws = await WebSocketTransformer.upgrade(request);
            ws.pingInterval = const Duration(seconds: 30);
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
      startError.value = e.toString();
      isRunning.value = false;
    }
  }

  void _cleanupClient(WebSocket ws) {
    _clients.remove(ws);
    _authTimers[ws]?.cancel();
    _authTimers.remove(ws);
    _invalidMessageCount.remove(ws);
    _lastBinaryPacketTime.remove(ws);
    if (_authenticatedClients.remove(ws)) {
      clientCount.value = _authenticatedClients.length;
      if (_authenticatedClients.isEmpty) {
        laserActive.value = false;
      }
    }
  }

  void _closeConnection(WebSocket ws, [int? code, String? reason]) {
    _cleanupClient(ws);
    try {
      if (code != null) {
        ws.close(code, reason);
      } else {
        ws.close();
      }
    } catch (_) {}
  }

  void _handleClient(WebSocket ws, String remoteIP) {
    _clients.add(ws);
    debugPrint('Client connected (awaiting auth). Total raw: ${_clients.length}');

    _authTimers[ws] = Timer(const Duration(seconds: 5), () {
      _authTimers.remove(ws);
      if (!_authenticatedClients.contains(ws)) {
        debugPrint('Client auth timeout – disconnecting');
        _closeConnection(ws, 4001, 'Auth timeout');
      }
    });

    ws.listen(
      (data) {
        try {
          if (data is List<int>) {
            if (!_authenticatedClients.contains(ws)) return;

            final now = DateTime.now().millisecondsSinceEpoch;
            final lastTime = _lastBinaryPacketTime[ws] ?? 0;
            if (now - lastTime < 8) {
              return; // Rate limit (throttle to ~125 Hz)
            }
            _lastBinaryPacketTime[ws] = now;

            if (data.length == 9) {
              final byteData = ByteData.sublistView(Uint8List.fromList(data));
              final typeId = byteData.getUint8(0);
              final dx = byteData.getFloat32(1, Endian.little);
              final dy = byteData.getFloat32(5, Endian.little);

              if (!dx.isFinite || !dy.isFinite || dx.abs() > 500 || dy.abs() > 500) {
                return;
              }

              if (typeId == 0 || typeId == 1) { // 0 = TOUCH, 1 = LASER
                if (typeId == 1) {
                  final isPptRunning = _stateBroadcaster.lastSlideState != null && _stateBroadcaster.lastSlideState!['error'] == null;
                  if (!isPptRunning) return;
                }
                if (typeId == 1 && InputSimulator.handlesLaserPointer) {
                  // The presenter draws the laser itself (Impress): keep the OS cursor still.
                  mouseController.trackDelta(dx.toDouble(), dy.toDouble());
                  InputSimulator.laserPointerMoved(
                    mouseController.currentX / mouseController.screenWidth,
                    mouseController.currentY / mouseController.screenHeight,
                  );
                } else {
                  mouseController.moveDelta(dx.toDouble(), dy.toDouble());
                }
                onMouseMove?.call(mouseController.currentX, mouseController.currentY);
              }
            }
            return;
          }

          final message = jsonDecode(data as String);

          if (!_authenticatedClients.contains(ws)) {
            final authPin = message['auth'] as String?;
            if (authPin == null) {
              debugPrint('Unauthenticated client sent non-auth message — disconnecting');
              _closeConnection(ws, 4002, 'Auth required');
              return;
            }
            if (authPin == pin.value) {
              _authTimers[ws]?.cancel();
              _authTimers.remove(ws);
              _authenticatedClients.add(ws);
              _authManager.recordSuccessfulAuth(remoteIP);
              
              clientCount.value = _authenticatedClients.length;
              ws.add(jsonEncode({
                'type': 'auth',
                'status': 'ok',
                'presenter': InputSimulator.presenter,
                'platform': Platform.operatingSystem,
              }));

              debugPrint('Client authenticated. Authenticated count: ${_authenticatedClients.length}');
              triggerSlideStateUpdate();
              
              Future.delayed(
                const Duration(milliseconds: 350),
                () => _stateBroadcaster.broadcastVolumeState(force: true),
              );
            } else {
              _authManager.recordFailedAttempt(remoteIP);
              ws.add(jsonEncode({'type': 'auth', 'status': 'fail'}));
              debugPrint('Client auth failed (wrong PIN) from $remoteIP');
              _closeConnection(ws, 4003, 'Invalid PIN');
            }
            return;
          }

          final command = message['command'] as String?;
          if (command != null) {
            final baseCommand = command.contains(':') ? command.split(':')[0] : command;
            if (!RemoteCommands.allowedCommands.contains(command) &&
                !RemoteCommands.allowedPrefixes.contains(baseCommand)) {
              debugPrint('Rejected unknown command: $command');
              return;
            }
            
            final isPptRunning = _stateBroadcaster.lastSlideState != null && _stateBroadcaster.lastSlideState!['error'] == null;
            final pptModes = ['MODE_LASER', 'LASER_CURSOR', 'LASER_OFF', 'MODE_ARROW', 'MODE_PEN', 'MODE_HIGHLIGHTER', 'MODE_ERASER'];
            
            if (!isPptRunning && pptModes.contains(command)) {
              debugPrint('Ignored command $command because PowerPoint is not running');
              return;
            }

            lastCommand.value = command;
            InputSimulator.executeCommand(command);
            debugPrint('Executed: $command');

            if (command == 'VOLUME_UP' || command == 'VOLUME_DOWN' ||
                command == 'VOLUME_MUTE' || command.startsWith('VOLUME_SET:')) {
              _stateBroadcaster.scheduleVolumeStateBroadcast();
            }

            if (command == 'MODE_LASER') {
              laserActive.value = true;
            } else if (command == 'LASER_OFF') {
              laserActive.value = false;
            } else if (command == 'MODE_ARROW' || command == 'MODE_PEN' || command == 'MODE_HIGHLIGHTER' || command == 'MODE_ERASER') {
              laserActive.value = false;
            }

            if (command == 'NEXT' || command == 'PREV' || command == 'START' || command == 'END' || command.startsWith('START_AT:')) {
              triggerSlideStateUpdate(const Duration(milliseconds: 500));
            } else if (command == 'MEDIA_PLAY_PAUSE' || command == 'MEDIA_NEXT' || command == 'MEDIA_PREV' || command == 'SYSTEM_MEDIA_PLAY_PAUSE' || command == 'SYSTEM_MEDIA_NEXT' || command == 'SYSTEM_MEDIA_PREV' || command == 'SYSTEM_MEDIA_STOP') {
              triggerSlideStateUpdate(const Duration(milliseconds: 350));
            } else if (command == 'REFRESH_STATE') {
              triggerSlideStateUpdate();
              if (_stateBroadcaster.lastBroadcastVolume >= 0) {
                ws.add(jsonEncode({
                  'type': 'STATUS',
                  'state': 'VOLUME_CHANGED',
                  'volume': _stateBroadcaster.lastBroadcastVolume,
                  'muted': _stateBroadcaster.lastBroadcastMuted,
                }));
              }
              _stateBroadcaster.broadcastVolumeState(force: true);
            }

            ws.add(jsonEncode({'type': 'ack', 'command': command}));
            return;
          }

        } catch (e) {
          debugPrint('Error processing message: $e');
          _invalidMessageCount[ws] = (_invalidMessageCount[ws] ?? 0) + 1;
          if (_invalidMessageCount[ws]! >= 3) {
            debugPrint('Too many invalid messages — disconnecting client');
            _closeConnection(ws, 4004, 'Too many invalid messages');
          }
        }
      },
      onDone: () {
        _cleanupClient(ws);
        debugPrint('Client disconnected. Authenticated count: ${_authenticatedClients.length}');
      },
      onError: (error) {
        _cleanupClient(ws);
        debugPrint('Client error: $error');
      },
    );
  }

  Future<void> stop() async {
    _stopNetworkMonitor();
    _stateBroadcaster.stop();

    for (final client in _clients) {
      try {
        await client.close();
      } catch (_) {}
    }
    _clients.clear();
    _authenticatedClients.clear();
    _authManager.reset();
    
    clientCount.value = 0;
    laserActive.value = false;
    pin.value = '';
    NetworkManager.clearCachedIP();
    await _avahi.unregister();

    try {
      await _server?.close(force: true);
    } catch (e) {
      debugPrint('Error closing server: $e');
    }
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

  void triggerSlideStateUpdate([Duration delay = Duration.zero]) {
    _stateBroadcaster.triggerSlideStateUpdate(delay);
  }

  void _startNetworkMonitor() {
    _networkCheckTimer?.cancel();
    _networkProfileTick = 0;
    _networkCheckTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) async {
        final oldIP = localIP.value;
        final currentIP = await getLocalIP(force: true);
        
        if (oldIP != currentIP) {
          debugPrint('IP changed: $oldIP -> $currentIP');
        }

        _networkProfileTick++;
        if (_networkProfileTick >= 6) {
          _networkProfileTick = 0;
          final isPublic = await NetworkManager.checkNetworkProfile();
          if (isPublic != isPublicNetwork.value) {
            debugPrint('Network profile changed: ${isPublicNetwork.value ? "Public" : "Private"} → ${isPublic ? "Public" : "Private"}');
            isPublicNetwork.value = isPublic;
          }
        }
      },
    );
  }

  void _stopNetworkMonitor() {
    _networkCheckTimer?.cancel();
    _networkCheckTimer = null;
  }

  Future<void> openNetworkSettings() async {
    await NetworkManager.openNetworkSettings();
  }

  Future<bool> setNetworkProfilePrivate() async {
    final success = await NetworkManager.setNetworkProfilePrivate();
    if (success) {
      isPublicNetwork.value = false;
    }
    return success;
  }
}
