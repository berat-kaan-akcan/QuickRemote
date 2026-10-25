import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:quick_remote_shared/quick_remote_shared.dart';

import '../../theme/app_color_theme.dart';
import '../../utils/delta_accumulator.dart';
import '../bluetooth/bt_hid_service.dart';
import '../bluetooth/bt_key_mapping.dart';
import '../discovery_service.dart';
import '../presentation_timer_controller.dart';
import '../websocket_service.dart';

/// Lets the watch app (quick_remote_wear) use this phone's connection to the
/// PC. The watch talks to the native WearRelay over the Wearable Data Layer;
/// this is the Dart end of it. A command from the watch is sent as if it were
/// pressed on the phone's own screen, so the PC sees one client, and the
/// watch is told what a remote needs to show: whether a PC is connected, its
/// name, and the slide.
///
/// Either of the phone's connections serves: the Wi-Fi one, or, while there
/// is none, the Bluetooth keyboard ([BtHidService]). A keyboard gets no
/// answer from the computer, so over Bluetooth the watch is told no slide
/// and no errors, and the laser is the program's shortcut and the mouse.
///
/// It stays silent until a watch asks ([_watchSeen]): most phones have none.
///
/// The talk's clock is kept here too, for the watch to show and to vibrate
/// with: the presentation timer of the remote screen while it runs
/// ([attachTimer]), otherwise one of its own, from when the show started
/// (over Bluetooth: from the watch's START) to its end. Its length is shared
/// by the phone's timer and the watch ([talkDuration]); its warnings go to
/// the watch as alerts, which the watch vibrates also in the background.
class WearBridge {
  /// [btTarget] is the program the user picked for the Bluetooth remote
  /// (`SettingsProvider.btTarget`): its shortcuts differ. [talkDuration] and
  /// [setTalkDuration] keep the talk's length (`SettingsProvider.talkDuration`),
  /// [timerAlerts] what the timer warns with. [watchTheme] is the color
  /// theme the watch is to use ([watchThemeOf]), null while the phone's
  /// "use on the watch" switch is off. [settings] tells when they change.
  WearBridge(
    this._ws,
    this._discovery, {
    BtHidService? bt,
    BtTarget Function()? btTarget,
    int Function()? talkDuration,
    void Function(int seconds)? setTalkDuration,
    TimerAlerts Function()? timerAlerts,
    String? Function()? watchTheme,
    Listenable? settings,
    Future<bool> Function()? askNearbyDevices,
    MethodChannel channel = const MethodChannel('com.quickremote.quick_remote_app/wear'),
    DateTime Function() now = DateTime.now,
  })  : _bt = bt ?? BtHidService.instance,
        _btTarget = btTarget ?? (() => BtTarget.powerpoint),
        _talkDuration = talkDuration ?? (() => 0),
        _setTalkDuration = setTalkDuration ?? ((_) {}),
        _timerAlerts = timerAlerts ?? (() => const TimerAlerts()),
        _watchTheme = watchTheme ?? (() => null),
        _settings = settings,
        _askNearbyDevices = askNearbyDevices ?? _requestBluetoothConnect,
        _channel = channel,
        _now = now {
    _channel.setMethodCallHandler(_onCall);
    _ws.addListener(_onChange);
    _discovery.addListener(_onChange);
    _settings?.addListener(_onChange);
    _ownClock = PresentationTimerController(clock: now)
      ..warningTimes = (() => _timerAlerts().warnings.keys.toList())
      ..onAlert = _onOwnAlert;
    _btStates = _bt.stateStream.listen((_) => _onChange());
  }

  /// A PC error in the user's language, set by the UI (main.dart): services
  /// hold no text, and the watch shows the phone's wording.
  static String Function(Failure failure)? failureText;

  /// What the watch may send. It has buttons for nothing else.
  static const watchCommands = <String>{
    RemoteCommands.next,
    RemoteCommands.prev,
    RemoteCommands.start,
    RemoteCommands.end,
    RemoteCommands.blackScreen,
    RemoteCommands.whiteScreen,
    RemoteCommands.modeLaser,
    RemoteCommands.laserOff,
    RemoteCommands.modeArrow,
  };

  /// The laser goes out when the watch has sent nothing for this long: it
  /// went out of reach with the finger down. A finger held still sends an
  /// empty movement every second.
  static const laserSilence = Duration(seconds: 3);

  /// A PC error this soon after a watch command is the watch's to show.
  static const errorWindow = Duration(seconds: 3);

  /// The watch's laser movement is in the Wi-Fi touchpad's units (8 per
  /// logical pixel, touchpad_view.dart); the Bluetooth touchpad moves the
  /// mouse by 4 (bt_touchpad_view.dart).
  static const bluetoothMoveScale = 0.5;

  /// One mouse report's limit per axis.
  static const _mouseStep = 127;

  /// The watch's name for a color theme (WearTheme.wire there). A watch is
  /// always dark, so light-only Sunset shows as Cobalt.
  static String watchThemeOf(AppColorTheme theme) => switch (theme) {
        AppColorTheme.cobalt || AppColorTheme.sunset => 'cobalt',
        AppColorTheme.oled => 'oled',
        AppColorTheme.highContrast => 'contrast',
        AppColorTheme.mint => 'mint',
        AppColorTheme.violet => 'violet',
      };

  final WebSocketService _ws;
  final DiscoveryService _discovery;
  final BtHidService _bt;
  final BtTarget Function() _btTarget;
  final int Function() _talkDuration;
  final void Function(int seconds) _setTalkDuration;
  final TimerAlerts Function() _timerAlerts;
  final String? Function() _watchTheme;
  final Listenable? _settings;
  final Future<bool> Function() _askNearbyDevices;
  bool _nearbyAsked = false;

  /// The remote screen's timer, while that screen is open.
  PresentationTimerController? _timer;
  void Function(TimerAlert alert)? _timerOwnAlert;
  int? _timerTarget;

  /// The talk's clock while the phone's timer does not run.
  late final PresentationTimerController _ownClock;
  bool _showWasRunning = false;
  late final StreamSubscription<BtHidConnectionState> _btStates;
  final MethodChannel _channel;
  final DateTime Function() _now;

  bool _watchSeen = false;
  Map<String, Object>? _sent;
  Failure? _lastError;
  DateTime? _commandAt;

  final _names = <String, String>{};

  bool _laserOn = false;
  Timer? _laserTimer;

  /// The PC's per-frame limit, as on the phone's touchpad.
  final _moves = DeltaAccumulator(maxStep: 500);

  /// Mouse movement not sent yet: the fraction below one count.
  double _mouseX = 0;
  double _mouseY = 0;

  /// The Wi-Fi connection comes first: it does everything Bluetooth does.
  bool get _overBluetooth => !_ws.isConnected && _bt.isConnected;
  bool get _hasPc => _ws.isConnected || _bt.isConnected;

  Future<Object?> _onCall(MethodCall call) async {
    switch (call.method) {
      case 'hello':
        _watchSeen = true;
        _pushState(force: true);
        unawaited(_openDirectLink());
      case 'command':
        final command = call.arguments;
        if (command is String) _onCommand(command);
      case 'duration':
        final seconds = call.arguments;
        if (seconds is int && seconds >= 0) _onWatchDuration(seconds);
      case 'move':
        final delta = call.arguments;
        if (delta is List && delta.length == 2 && delta[0] is double && delta[1] is double) {
          _onMove(delta[0] as double, delta[1] as double);
        }
    }
    return null;
  }

  /// The laser's own Bluetooth socket from the watch (WearDirect.kt) needs
  /// the "nearby devices" permission on the phone too. Only the Bluetooth
  /// remote asked for it, so a phone used over Wi-Fi never had it and the
  /// watch's laser went over the Data Layer: it lagged and stuttered. Asked
  /// once per run when a watch shows up, then the socket listens.
  Future<void> _openDirectLink() async {
    if (_nearbyAsked) return;
    _nearbyAsked = true;
    try {
      if (await _askNearbyDevices()) await _channel.invokeMethod<void>('startDirect');
    } catch (_) {
      // No Activity for the dialog, or no native end (tests): the Data Layer serves.
    }
  }

  static Future<bool> _requestBluetoothConnect() async =>
      (await Permission.bluetoothConnect.request()).isGranted;

  void _onCommand(String command) {
    _watchSeen = true;
    if (!watchCommands.contains(command) || !_hasPc) return;
    _commandAt = _now();
    if (command == RemoteCommands.modeLaser) {
      // The first movement comes over the watch's socket and the command
      // over the Data Layer, so the movement can come first and have turned
      // the laser on already. A second MODE_LASER put it away: PowerPoint's
      // Ctrl+L toggles, and the cursor showed in its place.
      if (_laserOn) {
        _armLaserTimer();
        return;
      }
      _laserOn = true;
      _mouseX = 0;
      _mouseY = 0;
      _armLaserTimer();
    } else if (command == RemoteCommands.laserOff) {
      _laserOn = false;
      _laserTimer?.cancel();
    } else if (_overBluetooth && command == RemoteCommands.start) {
      // A keyboard is told nothing: the show starts when the watch says so.
      _startOwnClock();
    } else if (_overBluetooth && command == RemoteCommands.end) {
      _stopOwnClock();
    }
    _send(command);
  }

  /// Over Wi-Fi the command itself; over Bluetooth the picked program's
  /// shortcut for it, as the Bluetooth remote's own buttons send it.
  void _send(String command) {
    if (_ws.isConnected) {
      _ws.sendCommand(command);
      return;
    }
    final action = BtKeyMapping.forCommand(command, target: _btTarget());
    if (action != null) unawaited(action.execute(_bt).catchError((Object _) {}));
  }

  void _onMove(double dx, double dy) {
    if (!_hasPc || !dx.isFinite || !dy.isFinite) return;
    // The laser was put away after a silence, or MODE_LASER was lost on the
    // way: movement means the finger is down.
    if (!_laserOn) _onCommand(RemoteCommands.modeLaser);
    _armLaserTimer();
    if (_overBluetooth) {
      _moveMouse(dx * bluetoothMoveScale, dy * bluetoothMoveScale);
      return;
    }
    _moves.add(dx, dy);
    for (var step = _moves.take(); step != null; step = _moves.take()) {
      _ws.sendTouchOrLaser('LASER', step.$1, step.$2);
    }
  }

  /// Whole counts go out in steps of one report; the fraction waits for the
  /// next movement, so that slow strokes still move.
  void _moveMouse(double dx, double dy) {
    _mouseX += dx;
    _mouseY += dy;
    var x = _mouseX.round();
    var y = _mouseY.round();
    _mouseX -= x;
    _mouseY -= y;
    while (x != 0 || y != 0) {
      final stepX = x.clamp(-_mouseStep, _mouseStep);
      final stepY = y.clamp(-_mouseStep, _mouseStep);
      unawaited(_bt.sendMouseMove(stepX, stepY).catchError((Object _) {}));
      x -= stepX;
      y -= stepY;
    }
  }

  void _armLaserTimer() {
    _laserTimer?.cancel();
    _laserTimer = Timer(laserSilence, () {
      _laserOn = false;
      if (!_hasPc) return;
      _send(RemoteCommands.laserOff);
      _send(RemoteCommands.modeArrow);
    });
  }

  void _onChange() {
    if (!_hasPc) {
      _laserOn = false;
      _laserTimer?.cancel();
    }
    // Over Wi-Fi the show's start and end start and stop the talk's clock.
    // A dropped connection keeps it: the show goes on meanwhile.
    if (_ws.isConnected) {
      final running = _ws.isPptRunning;
      if (running && !_showWasRunning) _startOwnClock();
      if (!running && _showWasRunning) _stopOwnClock();
      _showWasRunning = running;
    }
    final error = _ws.lastCommandError;
    if (!identical(error, _lastError)) {
      _lastError = error;
      _reportError(error);
    }
    _pushState();
  }

  /// The watch gets only the PC's answers to its own commands: an error for
  /// a button pressed on the phone belongs on the phone.
  void _reportError(Failure? error) {
    final at = _commandAt;
    if (error is! RemoteFailure || at == null || _now().difference(at) > errorWindow) return;
    final text = failureText?.call(error);
    if (text != null) _invoke('error', {'text': text});
  }

  void _pushState({bool force = false}) {
    if (!_watchSeen) return;
    final state = _state();
    if (!force && mapEquals(state, _sent)) return;
    _sent = state;
    _invoke('state', state);
  }

  Map<String, Object> _state() {
    final wifi = _ws.isConnected;
    final bluetooth = _overBluetooth;
    return {
      'link': switch (_ws.connectionState) {
        _ when wifi || bluetooth => 'connected',
        AppConnectionState.connecting || AppConnectionState.reconnecting => 'connecting',
        // The Bluetooth keyboard is trying a computer it knows.
        _ when _bt.connectionState == BtHidConnectionState.advertising && _bt.targetName != null => 'connecting',
        _ => 'disconnected',
      },
      // Over Bluetooth nothing below is known: the watch shows no slide.
      'mode': bluetooth ? 'bluetooth' : 'wifi',
      'pc': wifi ? _pcName() : (bluetooth ? _bt.connectedDeviceName ?? '' : ''),
      'running': wifi && _ws.isPptRunning,
      // The PC's overlay draws the laser outside a show too.
      'laserAnywhere': wifi && _ws.toolsAnywhere,
      // A PDF viewer or browser in front with no show: Start is full screen.
      'viewer': wifi && !_ws.isPptRunning && FrontWindow.isViewer(_ws.frontWindow),
      'current': wifi ? _ws.currentSlide : 0,
      'total': wifi ? _ws.totalSlides : 0,
      'pointer': _pointer(wifi: wifi),
      'duration': _talkDuration(),
      ..._clockState(),
      // Absent: the watch keeps the theme it has.
      'theme': ?_watchTheme(),
    };
  }

  // ─── The talk's clock ───────────────────────────────────────────────────

  /// The remote screen's timer, which the watch then shows and vibrates
  /// with while it runs. Until [detachTimer].
  void attachTimer(PresentationTimerController timer) {
    detachTimer();
    _timer = timer;
    _timerOwnAlert = timer.onAlert;
    timer.onAlert = (alert) {
      _timerOwnAlert?.call(alert);
      _sendAlert(alert);
    };
    // A length picked on the watch is the phone timer's too.
    final length = _talkDuration();
    if (!timer.isDurationSelected && length > 0) timer.setDuration(length);
    // The remote screen opened while the show ran: it takes over the clock
    // the watch was showing, rather than starting at 0:00.
    final own = _ownClock.startTime;
    if (own != null && !timer.isRunning) {
      timer.setDuration(_ownClock.targetSeconds);
      timer.startFrom(own);
      _timerStartedByShow = true;
      _ownClock.reset();
    }
    _timerTarget = timer.isDurationSelected ? timer.targetSeconds : null;
    timer.addListener(_onTimer);
    _pushState();
  }

  void detachTimer() {
    final timer = _timer;
    if (timer == null) return;
    timer.removeListener(_onTimer);
    timer.onAlert = _timerOwnAlert;
    _timer = null;
    _timerOwnAlert = null;
    // The remote screen closed during the talk: the watch's clock goes on
    // from where the phone's was.
    final started = timer.startTime;
    if (started != null) {
      _ownClock.setDuration(timer.targetSeconds);
      _ownClock.startFrom(started);
    }
    _timerStartedByShow = false;
    _pushState();
  }

  void _onTimer() {
    final timer = _timer!;
    // A length picked on the phone is the watch's too.
    final target = timer.isDurationSelected ? timer.targetSeconds : null;
    if (target != _timerTarget) {
      _timerTarget = target;
      if (target != null) _setTalkDuration(target);
    }
    _pushState();
  }

  void _onWatchDuration(int seconds) {
    _watchSeen = true;
    _setTalkDuration(seconds);
    final timer = _timer;
    if (timer != null && !timer.isRunning) {
      _timerTarget = seconds;
      timer.setDuration(seconds);
    }
    _pushState();
  }

  /// The phone's timer is the talk's clock while it runs or is paused.
  bool get _timerInUse {
    final timer = _timer;
    return timer != null && timer.isDurationSelected && (timer.isRunning || timer.elapsedSeconds > 0);
  }

  /// The remote screen's timer was started by the show, not by the user:
  /// the show's end resets it again.
  bool _timerStartedByShow = false;

  void _startOwnClock() {
    // The remote screen is open: its timer is the talk's clock, so the phone
    // and the watch always show the same one (the phone's stayed at 0:00
    // while the watch counted, 2026-10-25). A paused one goes on; one the
    // user already runs is left running.
    final timer = _timer;
    if (timer != null) {
      if (!timer.isRunning) {
        _timerStartedByShow = true;
        if (timer.isDurationSelected && timer.elapsedSeconds > 0) {
          timer.start();
        } else {
          timer.setDuration(timer.isDurationSelected ? timer.targetSeconds : _talkDuration(), start: true);
        }
      }
      return;
    }
    if (_ownClock.isRunning) return;
    _ownClock.setDuration(_talkDuration(), start: true);
    _pushState();
  }

  void _stopOwnClock() {
    final timer = _timer;
    if (_timerStartedByShow && timer != null) timer.reset();
    _timerStartedByShow = false;
    _ownClock.reset();
    _pushState();
  }

  /// The clock the watch shows: its length (0 counts up), when it started
  /// (ms since the epoch, while it runs) and, while paused, how far it got.
  Map<String, Object> _clockState() {
    final clock = _timerInUse ? _timer! : _ownClock;
    final started = clock.startTime;
    return {
      'timerTarget': clock.targetSeconds,
      'timerRunning': clock.isRunning,
      'timerStart': started?.millisecondsSinceEpoch ?? 0,
      // Only while paused: a running one would write every second.
      'timerElapsed': clock.isRunning ? 0 : clock.elapsedSeconds,
    };
  }

  void _onOwnAlert(TimerAlert alert) {
    // The phone's timer warns for itself while it is the clock.
    if (!_timerInUse) _sendAlert(alert);
  }

  void _sendAlert(TimerAlert alert) {
    if (!_watchSeen) return;
    final alerts = _timerAlerts();
    final pattern = alert.kind == TimerAlertKind.timeUp
        ? alerts.timeUp
        : alerts.warnings[alert.remainingSeconds] ?? 'double';
    _invoke('alert', {
      'kind': alert.kind == TimerAlertKind.timeUp ? 'timeUp' : 'warning',
      'seconds': alert.remainingSeconds,
      // Empty: shown, not vibrated.
      'pattern': pattern ?? '',
    });
  }

  /// What the watch's laser shows on the computer, so that it names it:
  /// 'laser', or 'cursor' (Impress has no laser shortcut: over Bluetooth the
  /// laser is the mouse). The watch also knows 'arrow', which the phone sent
  /// for Windows WPS before its laser pen (Ctrl+R) was found.
  String _pointer({required bool wifi}) {
    if (wifi) return 'laser';
    return _btTarget() == BtTarget.impress ? 'cursor' : 'laser';
  }

  /// The name the PC gave when it accepted the PIN. An older PC gives none:
  /// then its mDNS name when it was found on the network, else its address.
  /// An mDNS name once seen is kept, since the search starts over and stops
  /// while a PC is connected.
  String _pcName() {
    final told = _ws.pcName;
    if (told != null) return told;
    final address = _ws.serverAddress;
    final colon = address.lastIndexOf(':');
    final host = colon < 0 ? address : address.substring(0, colon);
    for (final device in _discovery.devices) {
      if (device.ip == host && device.name.isNotEmpty) _names[host] = device.name;
    }
    return _names[host] ?? host;
  }

  void _invoke(String method, Object arguments) {
    // No watch support in this build (tests, a phone without Play services).
    _channel.invokeMethod<void>(method, arguments).catchError((Object _) {});
  }

  void dispose() {
    detachTimer();
    _ownClock.dispose();
    _laserTimer?.cancel();
    _ws.removeListener(_onChange);
    _discovery.removeListener(_onChange);
    _settings?.removeListener(_onChange);
    _btStates.cancel();
    _channel.setMethodCallHandler(null);
  }
}

/// What the presentation timer warns with (the timer settings).
class TimerAlerts {
  const TimerAlerts({this.warnings = const {}, this.timeUp});

  /// Seconds left → vibration pattern ('short', 'double', 'long', 'triple').
  final Map<int, String> warnings;

  /// The pattern when the time is up; null: no vibration.
  final String? timeUp;
}
