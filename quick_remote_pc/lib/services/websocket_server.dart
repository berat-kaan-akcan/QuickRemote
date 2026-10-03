import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'input_simulator.dart';
import 'mouse_controller.dart';
import 'package:quick_remote_shared/quick_remote_shared.dart';

import 'server/auth_manager.dart';
import 'server/move_coalescer.dart';
import 'server/network_manager.dart';
import 'server/pre_auth_byte_limit.dart';
import 'server/state_broadcaster.dart';

/// An authenticated phone, as listed on the PC.
class ConnectedClient {
  ConnectedClient(this.id, this.address, this.since, {this.name});

  final int id;
  final String address;
  final DateTime since;

  /// What the phone calls itself (its user-given name or model), if it said.
  final String? name;

  static const maxNameLength = 40;

  /// Makes a phone-supplied name safe to show: no control or bidi override
  /// characters (which could make it read as another phone), single spaces,
  /// at most [maxNameLength] characters. Null if nothing is left.
  static String? sanitizeName(Object? raw) {
    if (raw is! String) return null;
    final cleaned = raw
        .replaceAll(RegExp(r'[\u0000-\u001F\u007F-\u009F\u200B-\u200F\u202A-\u202E\u2060-\u206F\uFEFF]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (cleaned.isEmpty) return null;
    final runes = cleaned.runes;
    if (runes.length <= maxNameLength) return cleaned;
    return '${String.fromCharCodes(runes.take(maxNameLength - 1)).trimRight()}…';
  }
}

/// WebSocket server that listens for commands from mobile clients.
class WebSocketServer {
  HttpServer? _server;
  final List<WebSocket> _clients = [];
  final ValueNotifier<bool> isRunning = ValueNotifier(false);
  final ValueNotifier<int> clientCount = ValueNotifier(0);
  final ValueNotifier<String> lastCommand = ValueNotifier('');
  final ValueNotifier<bool> laserActive = ValueNotifier(false);
  final ValueNotifier<String> pin = ValueNotifier('');
  /// Authenticated phones, in the order they connected.
  final ValueNotifier<List<ConnectedClient>> connectedClients = ValueNotifier(const []);
  /// Whether a phone has paired since the server started. The PC hides the
  /// QR code and PIN from then on, so a projected screen doesn't show them.
  final ValueNotifier<bool> pairedOnce = ValueNotifier(false);
  final Map<WebSocket, ConnectedClient> _clientInfo = {};
  int _nextClientId = 1;

  /// True while too many wrong PINs have paused all new pairing.
  final ValueNotifier<bool> pairingPaused = ValueNotifier(false);
  Timer? _pairingPauseTimer;
  final ValueNotifier<String> localIP = ValueNotifier('');
  final ValueNotifier<NetworkTrust> networkTrust = ValueNotifier(NetworkTrust.unknown);
  /// Why the last start() failed (null when it succeeded).
  /// Why the last start failed (the UI words it: l10n/start_error_text.dart).
  final ValueNotifier<Object?> startError = ValueNotifier(null);
  /// Whether the mDNS advertisement succeeded (auto-discovery on the phone).
  final ValueNotifier<bool> mdnsAvailable = ValueNotifier(true);
  /// TLS certificate fingerprint for the pairing QR code (see [PairingPayload]);
  /// null when it could not be read, and the QR code then omits it.
  final ValueNotifier<String?> certFingerprint = ValueNotifier(null);

  final MouseController mouseController;
  final Set<WebSocket> _authenticatedClients = {};

  final AuthManager _authManager = AuthManager();
  late final StateBroadcaster _stateBroadcaster;

  int _port = 8090;
  /// A slide state check that commands needing a slideshow wait for.
  Future<void>? _slideCheck;

  /// The running start(), so a second call waits for it instead of binding twice.
  Future<void>? _starting;

  final Map<WebSocket, Timer> _authTimers = {};
  /// Remote IP of every socket that still holds a pending-auth slot.
  final Map<WebSocket, String> _pendingAuth = {};
  final Map<WebSocket, int> _invalidMessageCount = {};
  final Map<WebSocket, MoveCoalescer> _moves = {};
  final Map<WebSocket, PreAuthByteLimit> _byteLimits = {};
  /// Clients that sent LEFT_DOWN without a LEFT_UP yet.
  final Set<WebSocket> _leftButtonHeld = {};

  /// The phone pointing or drawing right now (laser, pen, highlighter,
  /// eraser). Until its gesture ends, the other phones' pointer commands and
  /// motion are dropped: with the cursor, the laser and the mouse button
  /// shared, one phone lifting its finger would end the other's laser or
  /// cut its line.
  WebSocket? _gestureOwner;
  final Stopwatch _clock = Stopwatch()..start();
  Duration _gestureOwnerSeen = Duration.zero;
  /// Phones whose gesture began while another phone owned the pointer: the
  /// rest of that gesture is dropped too.
  final Set<WebSocket> _gestureBlocked = {};

  // Last press of a command in [_onePressCommands], see _isEchoOfOtherPhone.
  String? _lastPress;
  WebSocket? _lastPressBy;
  Duration _lastPressAt = Duration.zero;

  Timer? _networkCheckTimer;
  int _networkProfileTick = 0;

  final Duration _authTimeout;
  /// Commands and the auth message are a few dozen bytes; anything larger is abuse.
  static const _maxTextMessageLength = 1024;
  /// Bytes a client may send before it authenticates: the auth message plus
  /// framing is a few dozen bytes.
  static const _preAuthByteBudget = 4096;
  /// Per-frame limit for every client. UTF-8 needs at most 4 bytes per char.
  static const _maxFramePayload = _maxTextMessageLength * 4;
  static const _moveInterval = Duration(milliseconds: 8); // ~125 Hz

  /// Only meaningful inside a running slideshow. Outside one they would type
  /// shortcuts (Ctrl+P, Ctrl+A, E, ...) into whatever window has the focus.
  static const _slideshowOnlyCommands = {
    RemoteCommands.modeLaser,
    RemoteCommands.laserCursor,
    RemoteCommands.laserOff,
    RemoteCommands.modeArrow,
    RemoteCommands.modePen,
    RemoteCommands.modeHighlighter,
    RemoteCommands.modeEraser,
    RemoteCommands.eraseAll,
    RemoteCommands.blackScreen,
    RemoteCommands.whiteScreen,
  };

  static const _gestureStartCommands = {
    RemoteCommands.modeLaser,
    RemoteCommands.laserCursor,
    RemoteCommands.modePen,
    RemoteCommands.modeHighlighter,
    RemoteCommands.modeEraser,
  };

  /// Commands that act on the shared pointer, see [_gestureOwner].
  static const _gestureCommands = {
    ..._gestureStartCommands,
    RemoteCommands.modeArrow, // every gesture ends with it
    RemoteCommands.laserOff,
    RemoteCommands.leftDown,
    RemoteCommands.leftUp,
    RemoteCommands.leftClick,
    RemoteCommands.rightClick,
  };

  /// An owner silent this long is taken to be gone. A phone ends every
  /// gesture with MODE_ARROW, and a closed socket releases it at once, so
  /// this only covers an app that stopped mid-gesture.
  static const _gestureOwnerTimeout = Duration(seconds: 15);

  /// Presses two people make at once to do one thing (both see the slide is
  /// done and press NEXT). A second phone repeating one within
  /// [_samePressWindow] is ignored; the toggles would otherwise undo it.
  static const _onePressCommands = {
    RemoteCommands.next,
    RemoteCommands.prev,
    RemoteCommands.blackScreen,
    RemoteCommands.whiteScreen,
    RemoteCommands.mediaPlayPause,
    RemoteCommands.sysMediaPlayPause,
    RemoteCommands.sysMediaNext,
    RemoteCommands.sysMediaPrev,
    RemoteCommands.volumeMute,
  };
  static const _samePressWindow = Duration(milliseconds: 300);

  static const _volumeCommands = {
    RemoteCommands.volumeUp,
    RemoteCommands.volumeDown,
    RemoteCommands.volumeMute,
  };
  /// Modes that end the laser.
  static const _otherModeCommands = {
    RemoteCommands.modeArrow,
    RemoteCommands.modePen,
    RemoteCommands.modeHighlighter,
    RemoteCommands.modeEraser,
  };
  /// Change the slide: the state is refreshed shortly after.
  static const _slideCommands = {
    RemoteCommands.next,
    RemoteCommands.prev,
    RemoteCommands.start,
    RemoteCommands.end,
  };
  static const _mediaCommands = {
    RemoteCommands.mediaPlayPause,
    RemoteCommands.sysMediaPlayPause,
    RemoteCommands.sysMediaNext,
    RemoteCommands.sysMediaPrev,
    RemoteCommands.sysMediaStop,
  };

  int get port => _port;

  WebSocketServer({
    MouseController? mouseController,
    Duration authTimeout = const Duration(seconds: 5),
  })  : mouseController = mouseController ?? MouseController(),
        _authTimeout = authTimeout {
    _stateBroadcaster = StateBroadcaster(
      onBroadcast: broadcast,
      hasClients: () => _authenticatedClients.isNotEmpty,
    );
  }

  bool get _isSlideshowRunning =>
      _stateBroadcaster.lastSlideState != null && _stateBroadcaster.lastSlideState!['error'] == null;

  Future<String> getLocalIP({bool force = false}) async {
    final ip = await NetworkManager.getLocalIP(force: force);
    if (localIP.value != ip) {
      localIP.value = ip;
    }
    return ip;
  }

  Future<void> start({int port = 8090}) {
    if (_server != null) return Future.value();
    return _starting ??= _start(port).whenComplete(() => _starting = null);
  }

  Future<void> _start(int port) async {
    startError.value = null;
    pin.value = _authManager.generatePin();

    networkTrust.value = await NetworkManager.checkNetworkProfile();
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

      _serve();

      certFingerprint.value = await _ownCertFingerprint(_port);

      mdnsAvailable.value = await NetworkManager.advertise(name: Platform.localHostname, port: _port);

      _stateBroadcaster.startSlideStatePoller();
    } catch (e) {
      debugPrint('Failed to start server: $e');
      startError.value = e;
      isRunning.value = false;
      _stopNetworkMonitor();
      await _server?.close(force: true);
      _server = null;
    }
  }

  void _serve() {
    isRunning.value = true;
    debugPrint('WebSocket server started on port $_port');

    InputSimulator.onCommandError = (error, [info]) => broadcast(error.status(info));

    _server!.listen(_handleRequest, onError: (error) => debugPrint('Server error: $error'));
  }

  /// Serves on an already bound [server] without TLS, mDNS, the network
  /// monitor or the state poller, so tests can talk to it over plain ws://.
  @visibleForTesting
  void serveForTesting(HttpServer server) {
    _server = server;
    _port = server.port;
    pin.value = _authManager.generatePin();
    _serve();
  }

  Future<void> _handleRequest(HttpRequest request) async {
    if (!WebSocketTransformer.isUpgradeRequest(request)) {
      _reject(request, HttpStatus.upgradeRequired);
      return;
    }
    // Browsers always send Origin on a WebSocket handshake and the app never
    // does, so this keeps web pages from talking to the server.
    if (request.headers.value('origin') != null) {
      _reject(request, HttpStatus.forbidden);
      return;
    }

    final remoteIP = AuthManager.clientKey(request.connectionInfo?.remoteAddress);
    if (!_authManager.tryReservePending(remoteIP)) {
      debugPrint('Refused connection from $remoteIP (rate limit)');
      _reject(request, HttpStatus.tooManyRequests);
      return;
    }

    final WebSocket ws;
    final PreAuthByteLimit limited;
    try {
      (ws, limited) = await PreAuthByteLimit.upgrade(
        request,
        budget: _preAuthByteBudget,
        maxFramePayload: _maxFramePayload,
      );
    } catch (e) {
      _authManager.releasePending(remoteIP);
      debugPrint('WebSocket upgrade failed: $e');
      return;
    }
    ws.pingInterval = const Duration(seconds: 30);
    _byteLimits[ws] = limited;
    _handleClient(ws, remoteIP, request.connectionInfo?.remoteAddress);
  }

  static void _reject(HttpRequest request, int status) {
    try {
      request.response
        ..statusCode = status
        ..close();
    } catch (_) {}
  }

  /// Reads the certificate clients will see with one TLS handshake to
  /// ourselves over loopback. Works the same for the PEM (Linux) and PFX
  /// (Windows) certificate files.
  static Future<String?> _ownCertFingerprint(int port) async {
    SecureSocket? socket;
    try {
      X509Certificate? seen;
      socket = await SecureSocket.connect(
        InternetAddress.loopbackIPv4,
        port,
        onBadCertificate: (cert) {
          seen = cert;
          return true;
        },
        timeout: const Duration(seconds: 3),
      );
      final der = (seen ?? socket.peerCertificate)?.der;
      if (der == null) return null;
      return PairingPayload.encodeFingerprint(sha256.convert(der).bytes);
    } catch (e) {
      debugPrint('Could not read own certificate fingerprint: $e');
      return null;
    } finally {
      socket?.destroy();
    }
  }

  void _releasePending(WebSocket ws) {
    final ip = _pendingAuth.remove(ws);
    if (ip != null) _authManager.releasePending(ip);
  }

  void _cleanupClient(WebSocket ws) {
    _clients.remove(ws);
    _authTimers.remove(ws)?.cancel();
    _releasePending(ws);
    _invalidMessageCount.remove(ws);
    _moves.remove(ws)?.dispose();
    _byteLimits.remove(ws);
    if (_leftButtonHeld.remove(ws)) {
      // The phone went away mid-drag: don't leave the button pressed on the PC.
      InputSimulator.executeCommand(RemoteCommands.leftUp);
    }
    _gestureBlocked.remove(ws);
    if (_gestureOwner == ws) {
      _gestureOwner = null;
      // Mid-gesture: put the laser or pen away, as the phone would have.
      if (_isSlideshowRunning) InputSimulator.executeCommand(RemoteCommands.modeArrow);
    }
    if (_lastPressBy == ws) _lastPressBy = null;
    _pendingAddress.remove(ws);
    if (_clientInfo.remove(ws) != null) _publishClients();
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

  static void _send(WebSocket ws, Map<String, dynamic> message) {
    try {
      ws.add(jsonEncode(message));
    } catch (e) {
      debugPrint('Send failed: $e');
    }
  }

  /// Address of each socket still waiting to authenticate, for the client list.
  final Map<WebSocket, InternetAddress?> _pendingAddress = {};

  void _handleClient(WebSocket ws, String remoteIP, InternetAddress? address) {
    _pendingAddress[ws] = address;
    _clients.add(ws);
    _pendingAuth[ws] = remoteIP;
    debugPrint('Client connected (awaiting auth). Total raw: ${_clients.length}');

    _authTimers[ws] = Timer(_authTimeout, () {
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
            if (!_authenticatedClients.contains(ws)) {
              _closeConnection(ws, 4002, 'Auth required');
              return;
            }
            _handleMoveFrame(ws, data);
            return;
          }

          final text = data as String;
          if (text.length > _maxTextMessageLength) {
            debugPrint('Oversized message (${text.length} chars) — disconnecting client');
            _closeConnection(ws, WebSocketStatus.messageTooBig, 'Message too big');
            return;
          }
          final message = jsonDecode(text);

          if (!_authenticatedClients.contains(ws)) {
            _handleAuth(ws, remoteIP, message);
            return;
          }

          final command = message['command'] as String?;
          if (command != null) _handleCommand(ws, command);
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

  void _handleAuth(WebSocket ws, String remoteIP, dynamic message) {
    final candidate = message['auth'];
    if (candidate is! String) {
      debugPrint('Unauthenticated client sent non-auth message — disconnecting');
      _closeConnection(ws, 4002, 'Auth required');
      return;
    }

    // Checked on every attempt, not only on connect: this socket may have
    // been opened before its IP (or the whole server) hit the rate limit.
    if (!_authManager.canAttemptAuth(remoteIP)) {
      _send(ws, {'type': 'auth', 'status': 'fail', 'reason': 'rate_limited'});
      _closeConnection(ws, 4008, 'Too many attempts');
      return;
    }

    if (!AuthManager.verifyPin(candidate, pin.value)) {
      if (_authManager.recordFailedAttempt(remoteIP)) _onPairingPaused();
      _send(ws, {'type': 'auth', 'status': 'fail'});
      debugPrint('Client auth failed (wrong PIN) from $remoteIP');
      _closeConnection(ws, 4003, 'Invalid PIN');
      return;
    }

    _authTimers.remove(ws)?.cancel();
    _releasePending(ws);
    _byteLimits.remove(ws)?.lift();
    _authenticatedClients.add(ws);
    // The rate-limit key, except that IPv6 shows the full address, not its /64.
    final address = _pendingAddress.remove(ws);
    final shown = address?.type == InternetAddressType.IPv6 && !remoteIP.contains('.')
        ? address!.address
        : remoteIP;
    _clientInfo[ws] = ConnectedClient(
      _nextClientId++,
      shown,
      DateTime.now(),
      name: ConnectedClient.sanitizeName(message['name']),
    );
    _publishClients();
    pairedOnce.value = true;
    _authManager.recordSuccessfulAuth(remoteIP);

    clientCount.value = _authenticatedClients.length;
    _send(ws, {
      'type': 'auth',
      'status': 'ok',
      'presenter': InputSimulator.presenter,
      'presenters': InputSimulator.presenters,
      'platform': Platform.operatingSystem,
    });

    debugPrint('Client authenticated. Authenticated count: ${_authenticatedClients.length}');
    _stateBroadcaster.resendSmtcInFull();
    triggerSlideStateUpdate();

    Future.delayed(
      const Duration(milliseconds: 350),
      () => _stateBroadcaster.broadcastVolumeState(force: true),
    );
  }

  void _publishClients() {
    connectedClients.value = List.unmodifiable(_clientInfo.values);
  }

  /// Disconnects a phone the user does not want, and replaces the PIN so it
  /// cannot pair again with the one it knows. Other phones stay connected.
  void kickClient(int id) {
    final ws = _clientInfo.entries.where((e) => e.value.id == id).firstOrNull?.key;
    if (ws == null) return;
    debugPrint('Client $id disconnected by the user — PIN replaced');
    pin.value = _authManager.generatePin();
    _closeConnection(ws, closedByPc, 'Disconnected by the PC');
  }

  /// Close code that tells the phone not to reconnect.
  static const closedByPc = 4005;

  /// Someone is guessing the PIN from several addresses: the old PIN may be
  /// partly searched, so replace it. Connected clients stay connected.
  void _onPairingPaused() {
    debugPrint('Too many wrong PINs — pairing paused, PIN replaced');
    pin.value = _authManager.generatePin();
    pairingPaused.value = true;
    _pairingPauseTimer?.cancel();
    _pairingPauseTimer = Timer(AuthManager.globalPauseDuration, () => pairingPaused.value = false);
  }

  void _handleMoveFrame(WebSocket ws, List<int> data) {
    if (data.length != 9) return;
    final bytes = ByteData.sublistView(data is Uint8List ? data : Uint8List.fromList(data));
    final typeId = bytes.getUint8(0); // 0 = TOUCH, 1 = LASER
    final dx = bytes.getFloat32(1, Endian.little);
    final dy = bytes.getFloat32(5, Endian.little);
    if (typeId > 1 || !dx.isFinite || !dy.isFinite || dx.abs() > 500 || dy.abs() > 500) {
      return;
    }
    if (!_allowsMotion(ws)) return;
    _moves
        .putIfAbsent(ws, () => MoveCoalescer(minInterval: _moveInterval, onMove: _applyMove))
        .add(typeId, dx, dy);
  }

  void _applyMove(int typeId, double dx, double dy) {
    if (typeId == 1) {
      if (!_isSlideshowRunning) {
        _checkSlideshow();
        return;
      }
      if (InputSimulator.handlesLaserPointer) {
        // The presenter draws the laser itself (Impress): keep the OS cursor still.
        mouseController.trackDelta(dx, dy);
        InputSimulator.laserPointerMoved(
          mouseController.currentX / mouseController.screenWidth,
          mouseController.currentY / mouseController.screenHeight,
        );
        return;
      }
    }
    mouseController.moveDelta(dx, dy);
  }

  /// Concurrent callers share one check.
  Future<void> _checkSlideshow() =>
      _slideCheck ??= _stateBroadcaster.fetchAndBroadcastSlideState().whenComplete(() => _slideCheck = null);

  /// Whether [ws] may run [command] while another phone may own the pointer.
  bool _allowsGesture(WebSocket ws, String command) {
    if (!_gestureCommands.contains(command)) return true;
    final owner = _currentGestureOwner();
    if (_gestureStartCommands.contains(command)) {
      if (owner != null && owner != ws) {
        _gestureBlocked.add(ws);
        _send(ws, RemoteError.pointerBusy.status());
        return false;
      }
      _gestureBlocked.remove(ws);
      _gestureOwner = ws;
      _gestureOwnerSeen = _clock.elapsed;
      return true;
    }
    if (_gestureBlocked.contains(ws)) {
      if (command == RemoteCommands.modeArrow) _gestureBlocked.remove(ws);
      return false;
    }
    if (owner == null) return true;
    if (owner != ws) return false;
    if (command == RemoteCommands.modeArrow) {
      _gestureOwner = null;
    } else {
      _gestureOwnerSeen = _clock.elapsed;
    }
    return true;
  }

  bool _allowsMotion(WebSocket ws) {
    if (_gestureBlocked.contains(ws)) return false;
    final owner = _currentGestureOwner();
    if (owner == null) return true;
    if (owner != ws) return false;
    _gestureOwnerSeen = _clock.elapsed;
    return true;
  }

  WebSocket? _currentGestureOwner() {
    if (_gestureOwner != null && _clock.elapsed - _gestureOwnerSeen > _gestureOwnerTimeout) {
      debugPrint('Pointer owner silent for ${_gestureOwnerTimeout.inSeconds} s — released');
      _gestureOwner = null;
    }
    return _gestureOwner;
  }

  /// Whether [command] repeats what another phone sent a moment ago. The
  /// same phone pressing twice is meant, and runs twice.
  bool _isEchoOfOtherPhone(WebSocket ws, String command) {
    if (!_onePressCommands.contains(command)) return false;
    final now = _clock.elapsed;
    if (command == _lastPress && ws != _lastPressBy && now - _lastPressAt < _samePressWindow) {
      return true;
    }
    _lastPress = command;
    _lastPressBy = ws;
    _lastPressAt = now;
    return false;
  }

  void _handleCommand(WebSocket ws, String command) {
    final baseCommand = command.contains(':') ? command.split(':')[0] : command;
    if (!RemoteCommands.allowedCommands.contains(command) &&
        !RemoteCommands.allowedPrefixes.contains(baseCommand)) {
      debugPrint('Rejected unknown command: $command');
      return;
    }

    if (!_allowsGesture(ws, command)) {
      debugPrint('Ignored $command: another phone is using the pointer');
      return;
    }
    if (_isEchoOfOtherPhone(ws, command)) {
      debugPrint('Ignored $command: another phone just sent it');
      _send(ws, {'type': 'ack', 'command': command});
      return;
    }
    _runCommand(ws, command);
  }

  void _runCommand(WebSocket ws, String command) {
    if (!_isSlideshowRunning && _slideshowOnlyCommands.contains(command)) {
      // After "not running" the poller skips a few rounds, so a show just
      // started on the PC may not be known yet: check once, then decide.
      _checkSlideshow().then((_) {
        if (!_isSlideshowRunning) {
          debugPrint('Ignored command $command because no slideshow is running');
        } else if (_authenticatedClients.contains(ws)) {
          _runCommand(ws, command);
        }
      });
      return;
    }

    if (command == RemoteCommands.leftDown) {
      _leftButtonHeld.add(ws);
    } else if (command == RemoteCommands.leftUp) {
      _leftButtonHeld.remove(ws);
    }

    lastCommand.value = command;
    InputSimulator.executeCommand(command);
    debugPrint('Executed: $command');

    if (_volumeCommands.contains(command) || command.startsWith('VOLUME_SET:')) {
      _stateBroadcaster.scheduleVolumeStateBroadcast();
    }

    if (command == RemoteCommands.modeLaser) {
      laserActive.value = true;
    } else if (command == RemoteCommands.laserOff) {
      laserActive.value = false;
    } else if (_otherModeCommands.contains(command)) {
      laserActive.value = false;
    }

    if (_slideCommands.contains(command) || command.startsWith('START_AT:')) {
      triggerSlideStateUpdate(const Duration(milliseconds: 500));
      if (command == RemoteCommands.start || command.startsWith('START_AT:')) {
        // PowerPoint's show can take seconds to open. A check that finds no
        // show makes the poller skip its next rounds, which kept the phone
        // on "not running" for 6-8 s after START.
        triggerSlideStateUpdate(const Duration(milliseconds: 1500));
        triggerSlideStateUpdate(const Duration(seconds: 3));
      }
    } else if (_mediaCommands.contains(command)) {
      triggerSlideStateUpdate(const Duration(milliseconds: 350));
    } else if (command == RemoteCommands.refreshState) {
      triggerSlideStateUpdate();
      if (_stateBroadcaster.lastBroadcastVolume >= 0) {
        _send(ws, {
          'type': 'STATUS',
          'state': 'VOLUME_CHANGED',
          'volume': _stateBroadcaster.lastBroadcastVolume,
          'muted': _stateBroadcaster.lastBroadcastMuted,
        });
      }
      _stateBroadcaster.broadcastVolumeState(force: true);
    }

    _send(ws, {'type': 'ack', 'command': command});
  }

  Future<void> stop() async {
    _stopNetworkMonitor();
    _stateBroadcaster.stop();

    for (final timer in _authTimers.values) {
      timer.cancel();
    }
    _authTimers.clear();
    for (final move in _moves.values) {
      move.dispose();
    }
    _moves.clear();
    if (_leftButtonHeld.isNotEmpty) {
      _leftButtonHeld.clear();
      InputSimulator.executeCommand(RemoteCommands.leftUp);
    }
    _pendingAuth.clear();
    _invalidMessageCount.clear();
    _gestureOwner = null;
    _gestureBlocked.clear();
    _lastPressBy = null;

    // Copy first: closing a socket runs its onDone, which edits these collections.
    final clients = List.of(_clients);
    _clients.clear();
    _authenticatedClients.clear();
    await Future.wait(clients.map((client) async {
      try {
        await client.close();
      } catch (_) {}
    })).timeout(const Duration(seconds: 2), onTimeout: () => const []);
    _authManager.reset();
    _clientInfo.clear();
    _pendingAddress.clear();
    _publishClients();
    pairedOnce.value = false;
    _pairingPauseTimer?.cancel();
    pairingPaused.value = false;

    clientCount.value = 0;
    laserActive.value = false;
    pin.value = '';
    certFingerprint.value = null;
    NetworkManager.clearCachedIP();
    await NetworkManager.unadvertise();

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
    for (final client in List.of(_authenticatedClients)) {
      try {
        client.add(encoded);
      } catch (e) {
        debugPrint('Broadcast to a client failed: $e');
      }
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
          final trust = await NetworkManager.checkNetworkProfile();
          if (trust != networkTrust.value) {
            debugPrint('Network profile changed: ${networkTrust.value.name} → ${trust.name}');
            networkTrust.value = trust;
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
}
