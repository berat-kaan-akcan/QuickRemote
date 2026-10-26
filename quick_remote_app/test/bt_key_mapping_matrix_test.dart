import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quick_remote_app/services/bluetooth/bt_hid_service.dart';
import 'package:quick_remote_app/services/bluetooth/bt_key_mapping.dart';
import 'package:quick_remote_shared/quick_remote_shared.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('com.quickremote.quick_remote_app/bt_hid');
  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return null;
    });
  });

  Future<List<MethodCall>> run(String command, BtTarget target) async {
    calls.clear();
    await BtKeyMapping.forCommand(command, target: target)
        ?.execute(BtHidService.instance);
    return List.of(calls);
  }

  test('forCommand never throws for any allowed command', () {
    for (final command in RemoteCommands.allowedCommands) {
      // Just must not throw for any target.
      for (final t in BtTarget.values) {
        BtKeyMapping.forCommand(command, target: t);
      }
    }
  });

  test('commands that need the PC app have no Bluetooth action', () {
    for (final t in BtTarget.values) {
      for (final command in [
        RemoteCommands.mediaPlayPause,
        RemoteCommands.mediaRewind,
        RemoteCommands.refreshState,
        RemoteCommands.startAt(3),
        RemoteCommands.penColor(255),
        'NOT_A_COMMAND',
        '',
      ]) {
        expect(BtKeyMapping.forCommand(command, target: t), isNull,
            reason: '$command / $t');
      }
    }
  });

  test('navigation and show keys are identical for every desktop program', () async {
    final expected = {
      RemoteCommands.next: (0, BtKeyMapping.keyPageDown),
      RemoteCommands.prev: (0, BtKeyMapping.keyPageUp),
      RemoteCommands.start: (0, BtKeyMapping.keyF5),
      RemoteCommands.end: (0, BtKeyMapping.keyEscape),
      RemoteCommands.blackScreen: (0, BtKeyMapping.keyB),
      RemoteCommands.whiteScreen: (0, BtKeyMapping.keyW),
    };
    // The sites in a browser have keys of their own (the next test).
    for (final t in [BtTarget.powerpoint, BtTarget.impress, BtTarget.wps]) {
      for (final e in expected.entries) {
        final c = await run(e.key, t);
        expect(c.single.method, 'sendKeyReport', reason: '${e.key} $t');
        final a = c.single.arguments as Map;
        expect((a['modifier'], (a['keyCodes'] as List).single), e.value,
            reason: '${e.key} $t');
      }
    }
  });

  test('the sites in a browser start with Ctrl+F5 and have no ink', () async {
    Future<(Object?, Object?)?> key(String command, BtTarget target) async {
      final calls = await run(command, target);
      if (calls.isEmpty) return null;
      final a = calls.single.arguments as Map;
      return (a['modifier'], (a['keyCodes'] as List).single);
    }

    for (final t in [BtTarget.powerpointWeb, BtTarget.googleSlides]) {
      expect(await key(RemoteCommands.start, t), (BtKeyMapping.modLCtrl, BtKeyMapping.keyF5), reason: '$t');
      expect(await key(RemoteCommands.end, t), (0, BtKeyMapping.keyEscape), reason: '$t');
      for (final command in [
        RemoteCommands.modePen,
        RemoteCommands.modeHighlighter,
        RemoteCommands.modeEraser,
        RemoteCommands.eraseAll,
        RemoteCommands.modeArrow,
      ]) {
        expect(await key(command, t), isNull, reason: '$command $t');
      }
    }
    // PowerPoint for the web: no blank screen, no laser key (the cursor).
    for (final command in [
      RemoteCommands.blackScreen,
      RemoteCommands.whiteScreen,
      RemoteCommands.modeLaser,
      RemoteCommands.laserOff,
    ]) {
      expect(await key(command, BtTarget.powerpointWeb), isNull, reason: command);
    }
    // Google Slides: the arrows, B and W, and L, which toggles its laser.
    const slides = BtTarget.googleSlides;
    expect(await key(RemoteCommands.next, slides), (0, BtKeyMapping.keyRight));
    expect(await key(RemoteCommands.prev, slides), (0, BtKeyMapping.keyLeft));
    expect(await key(RemoteCommands.blackScreen, slides), (0, BtKeyMapping.keyB));
    expect(await key(RemoteCommands.modeLaser, slides), (0, BtKeyMapping.keyL));
    expect(await key(RemoteCommands.laserOff, slides), (0, BtKeyMapping.keyL));
  });

  test('lock is Win+L, on every target', () async {
    for (final t in BtTarget.values) {
      final a = (await run(RemoteCommands.lock, t)).single.arguments as Map;
      expect(a['modifier'], BtKeyMapping.modLGui);
      expect(a['keyCodes'], [BtKeyMapping.keyL]);
    }
  });

  test('volume and media go out as consumer usages', () async {
    final expected = {
      RemoteCommands.volumeUp: BtKeyMapping.consumerVolumeUp,
      RemoteCommands.volumeDown: BtKeyMapping.consumerVolumeDown,
      RemoteCommands.volumeMute: BtKeyMapping.consumerMute,
      RemoteCommands.sysMediaPlayPause: BtKeyMapping.consumerPlayPause,
      RemoteCommands.sysMediaNext: BtKeyMapping.consumerNextTrack,
      RemoteCommands.sysMediaPrev: BtKeyMapping.consumerPrevTrack,
      RemoteCommands.sysMediaStop: BtKeyMapping.consumerStop,
    };
    for (final t in BtTarget.values) {
      for (final e in expected.entries) {
        final c = await run(e.key, t);
        expect(c.single.method, 'sendConsumerControl', reason: e.key);
        expect((c.single.arguments as Map)['usageId'], e.value,
            reason: '${e.key} $t');
      }
    }
  });

  test('mouse: left and right click, LEFT_UP sends nothing', () async {
    for (final t in BtTarget.values) {
      var c = await run(RemoteCommands.leftClick, t);
      expect(c.single.method, 'sendMouseClick');
      expect((c.single.arguments as Map)['button'], 1);
      c = await run(RemoteCommands.rightClick, t);
      expect((c.single.arguments as Map)['button'], 2);
      c = await run(RemoteCommands.leftDown, t);
      expect((c.single.arguments as Map)['button'], 1);
      expect(await run(RemoteCommands.leftUp, t), isEmpty);
    }
  });

  test('WPS laser keys go out in order and the pen/eraser overrides do not leak',
      () async {
    final c = await run(RemoteCommands.modeLaser, BtTarget.wps);
    expect(c.length, 2);
    expect((c[0].arguments as Map)['keyCodes'], [BtKeyMapping.keyA]);
    expect((c[1].arguments as Map)['keyCodes'], [BtKeyMapping.keyR]);
    // PowerPoint's laser is still Ctrl+L.
    final p = await run(RemoteCommands.modeLaser, BtTarget.powerpoint);
    expect((p.single.arguments as Map)['keyCodes'], [BtKeyMapping.keyL]);
  });

  test('the default target is PowerPoint', () async {
    calls.clear();
    await BtKeyMapping.forCommand(RemoteCommands.modeLaser)!
        .execute(BtHidService.instance);
    expect((calls.single.arguments as Map)['keyCodes'], [BtKeyMapping.keyL]);
  });
}
