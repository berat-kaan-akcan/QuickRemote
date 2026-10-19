import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quick_remote_app/services/bluetooth/bt_hid_service.dart';
import 'package:quick_remote_app/services/bluetooth/bt_key_mapping.dart';
import 'package:quick_remote_app/services/discovery_service.dart';
import 'package:quick_remote_app/services/presentation_timer_controller.dart';
import 'package:quick_remote_app/services/wear/wear_bridge.dart';
import 'package:quick_remote_app/services/websocket_service.dart';
import 'package:quick_remote_shared/quick_remote_shared.dart';

/// The connection as the bridge sees it, with what it sent kept in [sent].
class FakeConnection extends WebSocketService {
  AppConnectionState state = AppConnectionState.disconnected;
  String address = '';
  bool running = false;
  int current = 0;
  int total = 0;
  Failure? error;
  String? name;
  String showProgram = 'powerpoint';
  String? platform;
  final sent = <Object>[];

  @override
  bool get isConnected => state == AppConnectionState.connected;
  @override
  AppConnectionState get connectionState => state;
  @override
  String get serverAddress => address;
  @override
  String? get pcName => name;
  @override
  String get presenter => showProgram;
  @override
  String? get pcPlatform => platform;
  @override
  bool get isPptRunning => running;
  @override
  int get currentSlide => current;
  @override
  int get totalSlides => total;
  @override
  Failure? get lastCommandError => error;

  @override
  void sendCommand(String command) => sent.add(command);
  @override
  void sendTouchOrLaser(String type, double dx, double dy) => sent.add((type, dx, dy));

  void connect192() {
    state = AppConnectionState.connected;
    address = '192.168.1.20:8765';
    notifyListeners();
  }

  void change() => notifyListeners();
}

class FakeDiscovery extends DiscoveryService {
  final found = <DiscoveredDevice>[];

  @override
  List<DiscoveredDevice> get devices => found;
}

/// The Bluetooth keyboard, with the reports it was asked to send in [sent].
class FakeKeyboard implements BtHidService {
  final _states = StreamController<BtHidConnectionState>.broadcast(sync: true);
  BtHidConnectionState state = BtHidConnectionState.disconnected;
  String? computer;
  String? target;
  final sent = <Object>[];

  void set(BtHidConnectionState next, {String? computer, String? target}) {
    state = next;
    this.computer = computer;
    this.target = target;
    _states.add(next);
  }

  @override
  Stream<BtHidConnectionState> get stateStream => _states.stream;
  @override
  BtHidConnectionState get connectionState => state;
  @override
  bool get isConnected => state == BtHidConnectionState.connected;
  @override
  String? get connectedDeviceName => computer;
  @override
  String? get targetName => target;

  @override
  Future<void> sendKeyCombo(List<int> modifiers, int keyCode) async =>
      sent.add((modifiers.fold(0, (all, m) => all | m), keyCode));
  @override
  Future<void> sendMouseMove(int dx, int dy, {int buttons = 0}) async => sent.add(('mouse', dx, dy));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// The talk's clock in the state while none runs.
const noClock = {'duration': 0, 'timerTarget': 0, 'timerRunning': false, 'timerStart': 0, 'timerElapsed': 0};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('com.quickremote.quick_remote_app/wear');
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  late FakeConnection ws;
  late FakeDiscovery discovery;
  late FakeKeyboard keyboard;
  late BtTarget program;
  late ValueNotifier<int> picked;
  late int length;
  late TimerAlerts alerts;
  late WearBridge bridge;
  late List<MethodCall> toWatch;
  late DateTime clock;
  late int nearbyAsked;
  late bool nearbyGranted;

  /// A message from the watch, as the native WearRelay hands it over.
  Future<void> fromWatch(String method, [Object? arguments]) async {
    await messenger.handlePlatformMessage(
      channel.name,
      const StandardMethodCodec().encodeMethodCall(MethodCall(method, arguments)),
      (_) {},
    );
  }

  List<Map<Object?, Object?>> states() =>
      [for (final call in toWatch) if (call.method == 'state') call.arguments as Map<Object?, Object?>];

  setUp(() {
    toWatch = [];
    nearbyAsked = 0;
    nearbyGranted = false;
    messenger.setMockMethodCallHandler(channel, (call) async {
      toWatch.add(call);
      return null;
    });
    ws = FakeConnection();
    discovery = FakeDiscovery();
    clock = DateTime(2026, 10, 13, 9);
    keyboard = FakeKeyboard();
    program = BtTarget.powerpoint;
    picked = ValueNotifier(0);
    length = 0;
    alerts = const TimerAlerts(warnings: {300: 'double', 60: 'long'}, timeUp: 'triple');
    bridge = WearBridge(
      ws,
      discovery,
      bt: keyboard,
      btTarget: () => program,
      talkDuration: () => length,
      setTalkDuration: (seconds) {
        length = seconds;
        picked.value++;
      },
      timerAlerts: () => alerts,
      settings: picked,
      now: () => clock,
      askNearbyDevices: () async {
        nearbyAsked++;
        return nearbyGranted;
      },
    );
    WearBridge.failureText = (failure) => 'text for ${(failure as RemoteFailure).error?.code}';
  });

  tearDown(() {
    bridge.dispose();
    messenger.setMockMethodCallHandler(channel, null);
  });

  test('nothing is written until a watch asks', () async {
    ws.connect192();
    expect(toWatch, isEmpty);

    await fromWatch('hello');
    expect(states(), [
      {'link': 'connected', 'mode': 'wifi', 'pc': '192.168.1.20', 'running': false, 'current': 0, 'total': 0, 'pointer': 'laser', ...noClock},
    ]);
  });

  test('a watch gets its laser socket: the permission is asked once, then it listens', () async {
    nearbyGranted = true;
    await fromWatch('hello');
    await fromWatch('hello');
    await pumpEventQueue();
    expect(nearbyAsked, 1);
    expect(toWatch.where((call) => call.method == 'startDirect'), hasLength(1));
  });

  test('without the permission the socket does not listen', () async {
    await fromWatch('hello');
    await pumpEventQueue();
    expect(nearbyAsked, 1);
    expect(toWatch.where((call) => call.method == 'startDirect'), isEmpty);
  });

  test('every hello is answered, a change is written once', () async {
    await fromWatch('hello');
    await fromWatch('hello');
    expect(states().map((s) => s['link']), ['disconnected', 'disconnected']);

    ws.connect192();
    ws.change();
    expect(states().length, 3);

    ws
      ..running = true
      ..current = 5
      ..total = 20
      ..change();
    expect(states().last, {
      'link': 'connected',
      'mode': 'wifi',
      'pc': '192.168.1.20',
      'running': true,
      'current': 5,
      'total': 20,
      'pointer': 'laser',
      // The show started: the talk's clock counts up from now.
      'duration': 0,
      'timerTarget': 0,
      'timerRunning': true,
      'timerStart': clock.millisecondsSinceEpoch,
      'timerElapsed': 0,
    });
  });

  test('connecting and reconnecting are told apart from no connection', () async {
    await fromWatch('hello');
    for (final state in [AppConnectionState.connecting, AppConnectionState.reconnecting]) {
      ws
        ..state = state
        ..change();
      expect(states().last['link'], 'connecting');
    }
    ws
      ..state = AppConnectionState.failed
      ..change();
    expect(states().last['link'], 'disconnected');
  });

  test('an older PC is named as mDNS found it, and keeps the name when the search starts over', () async {
    discovery.found.add(DiscoveredDevice(name: 'Ofis-PC', ip: '192.168.1.20', port: 8765));
    ws.connect192();
    await fromWatch('hello');
    expect(states().last['pc'], 'Ofis-PC');

    discovery.found.clear();
    await fromWatch('hello');
    expect(states().last['pc'], 'Ofis-PC');
  });

  test('the name the PC gives comes before the mDNS name', () async {
    discovery.found.add(DiscoveredDevice(name: 'Ofis-PC', ip: '192.168.1.20', port: 8765));
    ws
      ..name = 'berat-cachyos'
      ..connect192();
    await fromWatch('hello');
    expect(states().last['pc'], 'berat-cachyos');
  });

  test('Windows WPS has a laser too', () async {
    await fromWatch('hello');
    ws
      ..platform = 'windows'
      ..showProgram = 'wps'
      ..connect192();
    expect(states().last['pointer'], 'laser');
  });

  test('a watch command is sent as the phone would send it', () async {
    ws.connect192();
    await fromWatch('command', RemoteCommands.next);
    await fromWatch('command', RemoteCommands.blackScreen);
    expect(ws.sent, [RemoteCommands.next, RemoteCommands.blackScreen]);
  });

  test('commands the watch has no button for are dropped', () async {
    ws.connect192();
    await fromWatch('command', RemoteCommands.lock);
    await fromWatch('command', RemoteCommands.startAt(3));
    await fromWatch('command', 42);
    expect(ws.sent, isEmpty);
  });

  test('nothing is sent without a PC', () async {
    await fromWatch('command', RemoteCommands.next);
    await fromWatch('move', [4.0, 2.0]);
    expect(ws.sent, isEmpty);
  });

  test('laser movement goes out as LASER frames within the PC\'s limit', () async {
    ws.connect192();
    await fromWatch('command', RemoteCommands.modeLaser);
    await fromWatch('move', [1200.0, -30.0]);
    expect(ws.sent, [
      RemoteCommands.modeLaser,
      ('LASER', 500.0, -30.0),
      ('LASER', 500.0, 0.0),
      ('LASER', 200.0, 0.0),
    ]);
  });

  test('a MODE_LASER after the first movement does not toggle the laser off', () async {
    ws.connect192();
    // The movement came over the watch's socket, the command over the Data Layer.
    await fromWatch('move', [3.0, 4.0]);
    await fromWatch('command', RemoteCommands.modeLaser);
    expect(ws.sent, [RemoteCommands.modeLaser, ('LASER', 3.0, 4.0)]);
  });

  // testWidgets for its fake clock.
  testWidgets('the laser goes out when the watch falls silent, and comes back with movement', (tester) async {
    ws.connect192();
    await fromWatch('command', RemoteCommands.modeLaser);

    // A finger held still sends empty movement, which keeps the laser on.
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(seconds: 1));
      await fromWatch('move', [0.0, 0.0]);
    }
    expect(ws.sent, [RemoteCommands.modeLaser]);

    await tester.pump(WearBridge.laserSilence);
    expect(ws.sent, [RemoteCommands.modeLaser, RemoteCommands.laserOff, RemoteCommands.modeArrow]);

    ws.sent.clear();
    await fromWatch('move', [3.0, 4.0]);
    expect(ws.sent, [RemoteCommands.modeLaser, ('LASER', 3.0, 4.0)]);

    await fromWatch('command', RemoteCommands.laserOff);
    await tester.pump(WearBridge.laserSilence * 2);
    expect(ws.sent.last, RemoteCommands.laserOff);
  });

  group('over the Bluetooth keyboard', () {
    const ctrl = BtKeyMapping.modLCtrl;

    test('the watch is told the computer and that there is no slide to show', () async {
      await fromWatch('hello');
      keyboard.set(BtHidConnectionState.advertising, target: 'berat-cachyos');
      expect(states().last['link'], 'connecting');

      keyboard.set(BtHidConnectionState.connected, computer: 'berat-cachyos');
      expect(states().last, {
        'link': 'connected',
        'mode': 'bluetooth',
        'pc': 'berat-cachyos',
        'running': false,
        'current': 0,
        'total': 0,
        'pointer': 'laser',
        ...noClock,
      });

      keyboard.set(BtHidConnectionState.disconnected);
      expect(states().last['link'], 'disconnected');
    });

    test('a keyboard waiting for any computer is not connecting', () async {
      await fromWatch('hello');
      keyboard.set(BtHidConnectionState.advertising);
      expect(states().last['link'], 'disconnected');
    });

    test('commands go out as the keys the Bluetooth remote sends', () async {
      keyboard.set(BtHidConnectionState.connected, computer: 'PC');
      for (final command in [RemoteCommands.next, RemoteCommands.prev, RemoteCommands.start, RemoteCommands.end]) {
        await fromWatch('command', command);
      }
      expect(keyboard.sent, [
        (0, BtKeyMapping.keyPageDown),
        (0, BtKeyMapping.keyPageUp),
        (0, BtKeyMapping.keyF5),
        (0, BtKeyMapping.keyEscape),
      ]);
      expect(ws.sent, isEmpty);
    });

    test('the laser is the program\'s shortcut and the mouse', () async {
      keyboard.set(BtHidConnectionState.connected, computer: 'PC');
      await fromWatch('command', RemoteCommands.modeLaser);
      // Half the Wi-Fi touchpad's units; the fraction waits for more movement.
      await fromWatch('move', [9.0, -4.0]);
      await fromWatch('move', [1.0, 0.0]);
      await fromWatch('move', [600.0, 0.0]);
      await fromWatch('command', RemoteCommands.laserOff);
      expect(keyboard.sent, [
        (ctrl, BtKeyMapping.keyL),
        ('mouse', 5, -2),
        ('mouse', 127, 0),
        ('mouse', 127, 0),
        ('mouse', 46, 0),
        (ctrl, BtKeyMapping.keyA),
      ]);
    });

    test('the picked program decides the laser\'s keys', () async {
      keyboard.set(BtHidConnectionState.connected, computer: 'PC');
      // Impress has no laser shortcut: the mouse cursor is the laser.
      program = BtTarget.impress;
      await fromWatch('command', RemoteCommands.modeLaser);
      await fromWatch('move', [20.0, 0.0]);
      await fromWatch('command', RemoteCommands.laserOff);
      expect(keyboard.sent, [('mouse', 10, 0)]);

      keyboard.sent.clear();
      program = BtTarget.wps;
      await fromWatch('command', RemoteCommands.modeLaser);
      expect(keyboard.sent, [(ctrl, BtKeyMapping.keyA), (ctrl, BtKeyMapping.keyR)]);
    });

    test('the watch is told that the laser is the cursor in Impress', () async {
      program = BtTarget.impress;
      await fromWatch('hello');
      keyboard.set(BtHidConnectionState.connected, computer: 'PC');
      expect(states().last['pointer'], 'cursor');

      program = BtTarget.powerpoint;
      picked.value++;
      expect(states().last['pointer'], 'laser');
    });

    test('Wi-Fi comes first when both are connected', () async {
      keyboard.set(BtHidConnectionState.connected, computer: 'PC');
      ws.connect192();
      await fromWatch('hello');
      expect(states().last['mode'], 'wifi');
      await fromWatch('command', RemoteCommands.next);
      expect(ws.sent, [RemoteCommands.next]);
      expect(keyboard.sent, isEmpty);
    });

    testWidgets('the laser goes out when the watch falls silent', (tester) async {
      keyboard.set(BtHidConnectionState.connected, computer: 'PC');
      await fromWatch('command', RemoteCommands.modeLaser);
      await tester.pump(WearBridge.laserSilence);
      expect(keyboard.sent, [(ctrl, BtKeyMapping.keyL), (ctrl, BtKeyMapping.keyA), (ctrl, BtKeyMapping.keyA)]);
    });
  });

  test('the PC\'s answer to a watch command goes to the watch, in the phone\'s words', () async {
    ws.connect192();
    await fromWatch('command', RemoteCommands.next);
    clock = clock.add(const Duration(milliseconds: 400));
    ws
      ..error = const RemoteFailure(RemoteError.slideshowNotRunning)
      ..change();
    final errors = toWatch.where((call) => call.method == 'error').toList();
    expect(errors.single.arguments, {'text': 'text for NOT_RUNNING'});

    // The same failure object again (the remote screen has not cleared it).
    ws.change();
    expect(toWatch.where((call) => call.method == 'error').length, 1);
  });

  test('an error for a button pressed on the phone stays on the phone', () async {
    ws.connect192();
    await fromWatch('command', RemoteCommands.next);
    clock = clock.add(WearBridge.errorWindow + const Duration(seconds: 1));
    ws
      ..error = const RemoteFailure(RemoteError.noMedia)
      ..change();
    ws
      ..error = const ConnectionFailure(ConnectionError.closed)
      ..change();
    expect(toWatch.where((call) => call.method == 'error'), isEmpty);
  });

  group('the talk\'s clock', () {
    List<Map<Object?, Object?>> alertsSent() =>
        [for (final call in toWatch) if (call.method == 'alert') call.arguments as Map<Object?, Object?>];

    test('runs from the show\'s start for the length picked on the watch, and stops at its end', () async {
      await fromWatch('hello');
      await fromWatch('duration', 1200);
      expect(length, 1200);
      expect(states().last['duration'], 1200);

      ws
        ..connect192()
        ..running = true
        ..change();
      expect(states().last, containsPair('timerTarget', 1200));
      expect(states().last, containsPair('timerRunning', true));
      expect(states().last, containsPair('timerStart', clock.millisecondsSinceEpoch));

      ws
        ..running = false
        ..change();
      expect(states().last, containsPair('timerRunning', false));
    });

    test('a show started again runs from its own start', () async {
      await fromWatch('hello');
      ws
        ..connect192()
        ..running = true
        ..change();
      ws
        ..running = false
        ..change();
      clock = clock.add(const Duration(minutes: 18));
      ws
        ..running = true
        ..change();
      expect(states().last, containsPair('timerRunning', true));
      expect(states().last, containsPair('timerStart', clock.millisecondsSinceEpoch));
    });

    test('over Bluetooth it runs from the watch\'s start to its end', () async {
      keyboard.set(BtHidConnectionState.connected, computer: 'PC');
      await fromWatch('hello');
      await fromWatch('command', RemoteCommands.start);
      expect(states().last, containsPair('timerRunning', true));
      await fromWatch('command', RemoteCommands.end);
      expect(states().last, containsPair('timerRunning', false));
    });

    test('the phone\'s timer is the clock while it runs, and the length is shared', () async {
      await fromWatch('hello');
      // As the remote screen sets it up from the settings (bindTimerToSettings).
      final timer = PresentationTimerController(clock: () => clock)..warningTimes = (() => [300, 60]);
      addTearDown(timer.dispose);
      length = 900;
      bridge.attachTimer(timer);
      // The watch's length is the phone timer's.
      expect(timer.targetSeconds, 900);

      // A length picked on the phone is the watch's.
      timer.setDuration(600);
      expect(length, 600);
      expect(states().last['duration'], 600);

      timer.start();
      expect(states().last, containsPair('timerTarget', 600));
      expect(states().last, containsPair('timerStart', clock.millisecondsSinceEpoch));

      // Its warnings go to the watch with the settings' pattern.
      clock = clock.add(const Duration(seconds: 301));
      timer.tick();
      expect(alertsSent(), [
        {'kind': 'warning', 'seconds': 300, 'pattern': 'double'},
      ]);
      clock = clock.add(const Duration(seconds: 300));
      timer.tick();
      expect(alertsSent().last, {'kind': 'timeUp', 'seconds': 0, 'pattern': 'triple'});

      bridge.detachTimer();
      expect(states().last, containsPair('timerRunning', false));
    });

    test('a time-up without vibration is still told', () async {
      await fromWatch('hello');
      alerts = const TimerAlerts();
      final timer = PresentationTimerController(clock: () => clock);
      addTearDown(timer.dispose);
      bridge.attachTimer(timer);
      timer.setDuration(60, start: true);
      clock = clock.add(const Duration(seconds: 61));
      timer.tick();
      expect(alertsSent().single, {'kind': 'timeUp', 'seconds': 0, 'pattern': ''});
    });
  });
}
