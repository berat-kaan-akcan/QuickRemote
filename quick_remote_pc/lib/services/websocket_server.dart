import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:nsd/nsd.dart' as nsd;
import 'package:path_provider/path_provider.dart';
import 'input_simulator.dart';
import 'mouse_controller.dart';
import 'package:quick_remote_shared/quick_remote_shared.dart';

/// WebSocket server that listens for commands from mobile clients.
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
  nsd.Registration? _nsdRegistration;
  Timer? _slideStateTimer;
  Map<String, dynamic>? _lastSlideState;
  int _pptNotRunningSkipCount = 0;
  final Map<WebSocket, Timer> _authTimers = {};
  final Map<WebSocket, int> _invalidMessageCount = {};
  final Map<WebSocket, int> _lastBinaryPacketTime = {};
  final ValueNotifier<bool> isPublicNetwork = ValueNotifier(false);
  // Ses durumu — VOLUME_SET sonrası broadcast için
  int _lastBroadcastVolume = -1;
  bool _lastBroadcastMuted = false;
  Timer? _volumeStateTimer;
  Timer? _networkCheckTimer;

  /// Callback for laser position updates (for overlay).
  void Function(double x, double y)? onMouseMove;

  int get port => _port;

  String? _cachedIP;

  /// Get the local IP address of this machine.
  /// Uses PowerShell to find the active adapter with a default gateway (language-independent).
  /// Falls back to filtering virtual adapters if PowerShell fails.
  Future<String> getLocalIP() async {
    if (_cachedIP != null) return _cachedIP!;

    // Primary method: PowerShell (Language independent, relies on default gateway)
    try {
      final result = await Process.run('powershell', [
        '-NoProfile',
        '-NonInteractive',
        '-Command',
        r'(Get-NetIPConfiguration | Where-Object {$_.IPv4DefaultGateway -ne $null} | Select-Object -First 1).IPv4Address.IPAddress'
      ]);
      final output = (result.stdout as String).trim();
      if (output.isNotEmpty && output.contains('.')) {
        _cachedIP = output;
        return output;
      }
    } catch (e) {
      debugPrint('Failed to get IP via PowerShell: $e');
    }

    // Fallback method: Dart NetworkInterface
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
          fallbackIP ??= addr.address;
          // In fallback, just return the first non-virtual, non-loopback IP
          _cachedIP = fallbackIP;
          return fallbackIP;
        }
      }
    }
    
    _cachedIP = fallbackIP ?? '127.0.0.1';
    return _cachedIP!;
  }

  /// Generate a random 4-digit PIN.
  String _generatePin() {
    final rng = Random.secure();
    return (1000 + rng.nextInt(9000)).toString();
  }

  /// Generate a strong random password.
  String _generateSecurePassword() {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rng = Random.secure();
    return List.generate(32, (index) => chars[rng.nextInt(chars.length)]).join();
  }

  /// Load or generate a self-signed TLS certificate.
  Future<SecurityContext> _loadOrGenerateCert() async {
    final dir = await getApplicationSupportDirectory();
    final certPath = '${dir.path}\\server_cert.pfx';
    final pwdPath = '${dir.path}\\cert_pwd.txt';
    final file = File(certPath);
    final pwdFile = File(pwdPath);

    bool generate = true;
    if (file.existsSync()) {
      final stat = file.statSync();
      // Renew if older than 365 days
      if (DateTime.now().difference(stat.modified).inDays < 365) {
        generate = false;
      }
    }

    String certPassword = '1234'; // Default for backward compatibility
    
    if (generate) {
      debugPrint('Generating new self-signed TLS certificate...');
      certPassword = _generateSecurePassword();
      if (file.existsSync()) file.deleteSync();
      pwdFile.writeAsStringSync(certPassword);

      final script = '''
\$cert = New-SelfSignedCertificate -DnsName "QuickRemote" -CertStoreLocation "cert:\\CurrentUser\\My" -ErrorAction Stop
\$pwd = ConvertTo-SecureString -String "$certPassword" -Force -AsPlainText -ErrorAction Stop
Export-PfxCertificate -Cert \$cert -FilePath "$certPath" -Password \$pwd -ErrorAction Stop
Remove-Item -Path "cert:\\CurrentUser\\My\\\$(\$cert.Thumbprint)" -ErrorAction Stop
''';

      final res = await Process.run('powershell', ['-NoProfile', '-NonInteractive', '-Command', script]);
      if (res.exitCode != 0 || !file.existsSync()) {
        throw Exception('Failed to generate TLS certificate via PowerShell: \${res.stderr}');
      }
    } else {
       if (pwdFile.existsSync()) {
         certPassword = pwdFile.readAsStringSync().trim();
       }
    }

    final ctx = SecurityContext();
    ctx.useCertificateChain(certPath, password: certPassword);
    ctx.usePrivateKey(certPath, password: certPassword);
    return ctx;
  }

  /// Start the WebSocket server.
  /// If the default port is occupied, automatically tries the next ports
  /// (up to 10 attempts) until a free port is found.
  Future<void> start({int port = 8090}) async {
    if (_server != null) return;

    pin.value = _generatePin();

    // Check network profile before starting
    isPublicNetwork.value = await _checkNetworkProfile();
    _startNetworkMonitor();

    try {
      final ctx = await _loadOrGenerateCert();

      // Try binding to the requested port; if occupied, try next ports
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

      if (_nsdRegistration == null) {
        final hostname = Platform.localHostname;
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

      _startSlideStatePoller();

      // Wire up COM error callback to notify clients
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
    // Don't update clientCount yet — only count authenticated clients
    debugPrint('Client connected (awaiting auth). Total raw: ${_clients.length}');

    // Give the client 5 seconds to authenticate, otherwise disconnect
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
                  final isPptRunning = _lastSlideState != null && _lastSlideState!['error'] == null;
                  if (!isPptRunning) return; // Ignore LASER movement if PPT is not running/in presentation mode
                }
                mouseController.moveDelta(dx.toDouble(), dy.toDouble());
                onMouseMove?.call(mouseController.currentX, mouseController.currentY);
              }
            }
            return;
          }

          final message = jsonDecode(data as String);

          // --- Authentication gate ---
          if (!_authenticatedClients.contains(ws)) {
            final authPin = message['auth'] as String?;
            if (authPin == null) {
              // No auth key — reject immediately
              debugPrint('Unauthenticated client sent non-auth message — disconnecting');
              _closeConnection(ws, 4002, 'Auth required');
              return;
            }
            if (authPin == pin.value) {
              _authTimers[ws]?.cancel();
              _authTimers.remove(ws);
              _authenticatedClients.add(ws);
              _failedAttempts.remove(remoteIP);
              _blockedIPs.remove(remoteIP);
              clientCount.value = _authenticatedClients.length;
              ws.add(jsonEncode({'type': 'auth', 'status': 'ok'}));

              debugPrint('Client authenticated. Authenticated count: ${_authenticatedClients.length}');
              triggerSlideStateUpdate();
              // Every newly connected phone needs the current value, even when
              // another client already caused us to cache the same value.
              Future.delayed(
                const Duration(milliseconds: 350),
                () => _broadcastVolumeState(force: true),
              );
            } else {
              // Track failed attempt for brute-force protection
              _failedAttempts[remoteIP] = (_failedAttempts[remoteIP] ?? 0) + 1;
              if (_failedAttempts[remoteIP]! >= _maxFailedAttempts) {
                _blockedIPs[remoteIP] = DateTime.now().add(_blockDuration);
                debugPrint('IP blocked due to too many failed attempts: $remoteIP');
              }
              ws.add(jsonEncode({'type': 'auth', 'status': 'fail'}));
              debugPrint('Client auth failed (wrong PIN) from $remoteIP (attempt ${_failedAttempts[remoteIP]})');
              _closeConnection(ws, 4003, 'Invalid PIN');
            }
            return;
          }

          // Handle regular commands
          final command = message['command'] as String?;
          if (command != null) {
            // Whitelist check: only allow known commands
            final baseCommand = command.contains(':') ? command.split(':')[0] : command;
            if (!RemoteCommands.allowedCommands.contains(command) &&
                !RemoteCommands.allowedPrefixes.contains(baseCommand)) {
              debugPrint('Rejected unknown command: $command');
              return;
            }
            final isPptRunning = _lastSlideState != null && _lastSlideState!['error'] == null;
            final pptModes = ['MODE_LASER', 'LASER_CURSOR', 'LASER_OFF', 'MODE_ARROW', 'MODE_PEN', 'MODE_HIGHLIGHTER', 'MODE_ERASER'];
            
            if (!isPptRunning && pptModes.contains(command)) {
              debugPrint('Ignored command $command because PowerPoint is not running');
              return;
            }

            lastCommand.value = command;
            InputSimulator.executeCommand(command);
            debugPrint('Executed: $command');

            // Ses komutu ise ses durumunu broadcast et
            if (command == 'VOLUME_UP' || command == 'VOLUME_DOWN' ||
                command == 'VOLUME_MUTE' || command.startsWith('VOLUME_SET:')) {
              // Kısa gecikme sonrası gerçek seviyeyi al ve yayınla
              _scheduleVolumeStateBroadcast();
            }

            // Update laser active state based on mode commands
            if (command == 'MODE_LASER') {
              laserActive.value = true;
            } else if (command == 'LASER_OFF') {
              laserActive.value = false;
            } else if (command == 'MODE_ARROW' || command == 'MODE_PEN' || command == 'MODE_HIGHLIGHTER' || command == 'MODE_ERASER') {
              laserActive.value = false;
            }

            if (command == 'NEXT' || command == 'PREV' || command == 'START' || command == 'END' || command.startsWith('START_AT:')) {
              triggerSlideStateUpdate(const Duration(milliseconds: 500));
            } else if (command == 'MEDIA_PLAY_PAUSE' || command == 'MEDIA_NEXT' || command == 'MEDIA_PREV') {
              triggerSlideStateUpdate(const Duration(milliseconds: 350));
            } else if (command == 'REFRESH_STATE') {
              triggerSlideStateUpdate();
              if (_lastBroadcastVolume >= 0) {
                ws.add(jsonEncode({
                  'type': 'STATUS',
                  'state': 'VOLUME_CHANGED',
                  'volume': _lastBroadcastVolume,
                  'muted': _lastBroadcastMuted,
                }));
              }
              _broadcastVolumeState(force: true);
            }

            ws.add(jsonEncode({'type': 'ack', 'command': command}));
            return;
          }

        } catch (e) {
          debugPrint('Error processing message: $e');
          // Rate limit invalid messages
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

  /// Stop the WebSocket server.
  Future<void> stop() async {
    _stopNetworkMonitor();
    _slideStateTimer?.cancel();
    _slideStateTimer = null;
    _volumeStateTimer?.cancel();
    _volumeStateTimer = null;
    _lastSlideState = null;

    for (final client in _clients) {
      try {
        await client.close();
      } catch (_) {}
    }
    _clients.clear();
    _authenticatedClients.clear();
    _failedAttempts.clear();
    _blockedIPs.clear();
    clientCount.value = 0;
    laserActive.value = false;
    pin.value = '';
    _cachedIP = null; // Clear cached IP when stopping so we can fetch again on next start if network changed.

    // We intentionally DO NOT unregister mDNS here to prevent "ghost duplicate" 
    // devices on the network due to Windows mDNS bugs when toggling fast.
    // The service remains discoverable, but connections will be refused when stopped.

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

  void _startSlideStatePoller() {
    _slideStateTimer?.cancel();
    _pptNotRunningSkipCount = 0;
    _slideStateTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _fetchAndBroadcastSmtcState();
      _broadcastVolumeState();
      
      if (_pptNotRunningSkipCount > 0) {
        _pptNotRunningSkipCount--;
        return;
      }
      _fetchAndBroadcastSlideState();
    });
  }

  /// Coalesce slider updates and query Windows only after the user briefly stops.
  /// This prevents a slow PowerShell request from reporting an older value.
  void _scheduleVolumeStateBroadcast() {
    _volumeStateTimer?.cancel();
    _volumeStateTimer = Timer(
      const Duration(milliseconds: 350),
      _broadcastVolumeState,
    );
  }

  Future<void> _fetchAndBroadcastSmtcState() async {
    if (_authenticatedClients.isEmpty) return;
    
    final smtcState = await InputSimulator.getSmtcState();
    
    if (smtcState != null) {
      broadcast({
        'type': 'SMTC_STATE',
        'hasMedia': smtcState['hasMedia'] ?? false,
        'title': smtcState['title'],
        'artist': smtcState['artist'],
        'positionMs': smtcState['positionMs'] ?? 0,
        'durationMs': smtcState['durationMs'] ?? 0,
        'isPlaying': smtcState['isPlaying'] ?? false,
        'thumbnail': smtcState['thumbnail'],
      });
    }
  }

  Future<void> _fetchAndBroadcastSlideState() async {
    if (_authenticatedClients.isEmpty) return; // Don't poll if no one is listening

    final state = await InputSimulator.getSlideState();
    if (state != null) {
      if (state['error'] == 'POWERPOINT_NOT_RUNNING') {
        _pptNotRunningSkipCount = 3; // Skip 3 ticks
        if (_lastSlideState == null || _lastSlideState!['error'] != 'POWERPOINT_NOT_RUNNING') {
          _lastSlideState = state;
          broadcast({
            'type': 'STATUS',
            'state': 'POWERPOINT_NOT_RUNNING',
          });
          broadcast({
            'type': 'SLIDE_STATE',
            'data': null,
          });
        }
        return;
      }

      _pptNotRunningSkipCount = 0; // PowerPoint is running, reset to normal interval

      // Compare with last state to avoid spamming
      final current = state['current'];
      final total = state['total'];
      final notes = state['notes'];

      if (_lastSlideState == null ||
          _lastSlideState!['current'] != current ||
          _lastSlideState!['total'] != total ||
          _lastSlideState!['notes'] != notes ||
          _lastSlideState!['hasMedia'] != state['hasMedia'] ||
          _lastSlideState!['error'] != null) {
        
        _lastSlideState = state;
        
        broadcast({
          'type': 'SLIDE_STATE',
          'current': current,
          'total': total,
          'notes': notes,
          'hasMedia': state['hasMedia'] ?? false,
        });
      }
    }
  }

  void triggerSlideStateUpdate([Duration delay = Duration.zero]) {
    if (delay == Duration.zero) {
      _fetchAndBroadcastSmtcState();
      _fetchAndBroadcastSlideState();
    } else {
      Future.delayed(delay, () {
        _fetchAndBroadcastSmtcState();
        _fetchAndBroadcastSlideState();
      });
    }
  }

  /// Mevcut Windows ses seviyesini ve mute durumunu sorgulayarak istemcilere yayınlar.
  Future<void> _broadcastVolumeState({bool force = false}) async {
    if (_authenticatedClients.isEmpty) return;
    final script = '''
try {
\${InputSimulator.getAudioControlPSScript()}
    \$lv = [AudioControl.Audio]::GetVolume()
    \$mu = [AudioControl.Audio]::GetMute()
    Write-Output "{`"volume`":\$([int](\$lv * 100)),`"muted`":\$(if(\$mu){`"true`"}else{`"false`"})}"
} catch {
    Write-Output "ERROR"
}
''';
    try {
      final output = await InputSimulator.runPowerShellScript(script);
      if (output.startsWith('{')) {
        final data = jsonDecode(output) as Map<String, dynamic>;
        final volume = (data['volume'] as num?)?.toInt() ?? -1;
        final muted = data['muted'] as bool? ?? false;
        if (force || volume != _lastBroadcastVolume || muted != _lastBroadcastMuted) {
          _lastBroadcastVolume = volume;
          _lastBroadcastMuted = muted;
          broadcast({
            'type': 'STATUS',
            'state': 'VOLUME_CHANGED',
            'volume': volume,
            'muted': muted,
          });
        }
      }
    } catch (e) {
      debugPrint('_broadcastVolumeState error: $e');
    }
  }

  /// Check if the active Windows network profile is "Public".
  /// Returns true if any active connection is Public.
  Future<bool> _checkNetworkProfile() async {
    try {
      final result = await Process.run('powershell', [
        '-NoProfile',
        '-NonInteractive',
        '-Command',
        r'(Get-NetConnectionProfile | Where-Object {$_.IPv4Connectivity -ne "Disconnected"} | Select-Object -First 1).NetworkCategory',
      ]);
      final output = (result.stdout as String).trim();
      debugPrint('Network profile: \$output');
      return output.toLowerCase() == 'public';
    } catch (e) {
      debugPrint('Failed to check network profile: \$e');
      return false;
    }
  }

  // ─── Live Network Monitoring ──────────────────────────────────────────────

  /// Start periodic network profile monitoring (every 30 seconds).
  void _startNetworkMonitor() {
    _networkCheckTimer?.cancel();
    _networkCheckTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) async {
        final isPublic = await _checkNetworkProfile();
        if (isPublic != isPublicNetwork.value) {
          debugPrint('Network profile changed: ${isPublicNetwork.value ? "Public" : "Private"} → ${isPublic ? "Public" : "Private"}');
          isPublicNetwork.value = isPublic;
        }
      },
    );
  }

  /// Stop the periodic network profile monitor.
  void _stopNetworkMonitor() {
    _networkCheckTimer?.cancel();
    _networkCheckTimer = null;
  }

  // ─── Network Settings Helpers ─────────────────────────────────────────────

  /// Get the InterfaceAlias of the active network adapter.
  Future<String?> getActiveInterfaceAlias() async {
    try {
      final result = await Process.run('powershell', [
        '-NoProfile',
        '-NonInteractive',
        '-Command',
        r'(Get-NetConnectionProfile | Where-Object {$_.IPv4Connectivity -ne "Disconnected"} | Select-Object -First 1).InterfaceAlias',
      ]);
      final output = (result.stdout as String).trim();
      return output.isNotEmpty ? output : null;
    } catch (e) {
      debugPrint('Failed to get interface alias: \$e');
      return null;
    }
  }

  /// Attempt to set the active network profile to Private.
  /// Returns true if successful, false otherwise (e.g. if admin rights are needed).
  Future<bool> setNetworkProfilePrivate() async {
    try {
      final alias = await getActiveInterfaceAlias();
      if (alias == null) return false;

      final result = await Process.run('powershell', [
        '-NoProfile',
        '-NonInteractive',
        '-Command',
        'Set-NetConnectionProfile -InterfaceAlias "$alias" -NetworkCategory Private',
      ]);

      if (result.exitCode == 0) {
        debugPrint('Network profile set to Private for $alias');
        isPublicNetwork.value = false;
        return true;
      } else {
        debugPrint('Failed to set network profile: ${result.stderr}');
        return false;
      }
    } catch (e) {
      debugPrint('Error setting network profile: \$e');
      return false;
    }
  }

  /// Open Windows network settings.
  Future<void> openNetworkSettings() async {
    try {
      await Process.run('explorer', ['ms-settings:network-wifi']);
    } catch (e) {
      debugPrint('Failed to open network settings: \$e');
    }
  }
}
