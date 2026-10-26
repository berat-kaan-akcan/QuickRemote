import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quick_remote_app/services/bluetooth/bt_hid_service.dart';
import 'package:quick_remote_app/services/bluetooth/bt_key_mapping.dart';

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

  /// Runs [command] for [target] and returns the HID key report it sent
  /// as (modifier, keyCode), or null when nothing was sent.
  Future<(int, int)?> keyReport(String command, BtTarget target) async {
    await BtKeyMapping.forCommand(command, target: target)?.execute(BtHidService.instance);
    if (calls.isEmpty) return null;
    final args = calls.single.arguments as Map;
    return (args['modifier'] as int, (args['keyCodes'] as List).single as int);
  }

  const ctrl = BtKeyMapping.modLCtrl;

  test('PowerPoint keeps its drawing shortcuts', () async {
    expect(await keyReport('MODE_LASER', BtTarget.powerpoint), (ctrl, BtKeyMapping.keyL));
    calls.clear();
    expect(await keyReport('MODE_HIGHLIGHTER', BtTarget.powerpoint), (ctrl, BtKeyMapping.keyI));
    calls.clear();
    expect(await keyReport('MODE_ERASER', BtTarget.powerpoint), (ctrl, BtKeyMapping.keyE));
  });

  test('PowerPoint\'s arrow hides by itself: Ctrl+A, then Ctrl+U once', () async {
    await BtKeyMapping.forCommand('MODE_ARROW', target: BtTarget.powerpoint)!.execute(BtHidService.instance);
    expect(
      [for (final call in calls) ((call.arguments as Map)['modifier'], ((call.arguments as Map)['keyCodes'] as List).single)],
      [(ctrl, BtKeyMapping.keyA), (ctrl, BtKeyMapping.keyU)],
    );
    // LASER_OFF comes with a MODE_ARROW: a second Ctrl+U would hide the arrow.
    calls.clear();
    expect(await keyReport('LASER_OFF', BtTarget.powerpoint), (ctrl, BtKeyMapping.keyA));
  });

  test('Impress uses the shortcuts it supports', () async {
    expect(await keyReport('MODE_PEN', BtTarget.impress), (ctrl, BtKeyMapping.keyP));
    calls.clear();
    expect(await keyReport('MODE_ARROW', BtTarget.impress), (ctrl, BtKeyMapping.keyA));
    calls.clear();
    expect(await keyReport('ERASE_ALL', BtTarget.impress), (0, BtKeyMapping.keyE));
    calls.clear();
    expect(await keyReport('START', BtTarget.impress), (0, BtKeyMapping.keyF5));
    calls.clear();
    expect(await keyReport('NEXT', BtTarget.impress), (0, BtKeyMapping.keyPageDown));
  });

  test('Impress sends nothing for shortcuts it lacks', () async {
    for (final command in ['MODE_LASER', 'LASER_CURSOR', 'LASER_OFF', 'MODE_HIGHLIGHTER', 'MODE_ERASER']) {
      calls.clear();
      expect(await keyReport(command, BtTarget.impress), isNull, reason: command);
    }
  });

  test('WPS uses its own pen and eraser keys', () async {
    expect(await keyReport('MODE_PEN', BtTarget.wps), (ctrl, BtKeyMapping.keyP));
    calls.clear();
    expect(await keyReport('MODE_HIGHLIGHTER', BtTarget.wps), (ctrl, BtKeyMapping.keyI));
    calls.clear();
    expect(await keyReport('LASER_OFF', BtTarget.wps), (ctrl, BtKeyMapping.keyA));
    calls.clear();
    expect(await keyReport('ERASE_ALL', BtTarget.wps), (0, BtKeyMapping.keyE));
    calls.clear();
    expect(await keyReport('MODE_ERASER', BtTarget.wps), (ctrl, BtKeyMapping.keyE));
  });

  test('WPS\'s laser is Ctrl+R, after the arrow (Ctrl+A)', () async {
    // Ctrl+L is WPS's playback bar, not the laser.
    for (final command in ['MODE_LASER', 'LASER_CURSOR']) {
      calls.clear();
      await BtKeyMapping.forCommand(command, target: BtTarget.wps)!.execute(BtHidService.instance);
      expect(
        [for (final call in calls) ((call.arguments as Map)['modifier'], ((call.arguments as Map)['keyCodes'] as List).single)],
        [(ctrl, BtKeyMapping.keyA), (ctrl, BtKeyMapping.keyR)],
        reason: command,
      );
    }
  });

  test('the sites in a browser start with Ctrl+F5 and have no ink', () async {
    Future<(int, int)?> key(String command, BtTarget target) {
      calls.clear();
      return keyReport(command, target);
    }

    for (final t in [BtTarget.powerpointWeb, BtTarget.googleSlides]) {
      expect(await key('START', t), (ctrl, BtKeyMapping.keyF5), reason: '$t');
      expect(await key('END', t), (0, BtKeyMapping.keyEscape), reason: '$t');
      for (final command in ['MODE_PEN', 'MODE_HIGHLIGHTER', 'MODE_ERASER', 'ERASE_ALL', 'MODE_ARROW']) {
        expect(await key(command, t), isNull, reason: '$command $t');
      }
    }
    // PowerPoint for the web: no blank screen, no laser key (the cursor).
    for (final command in ['BLACK_SCREEN', 'WHITE_SCREEN', 'MODE_LASER', 'LASER_OFF']) {
      expect(await key(command, BtTarget.powerpointWeb), isNull, reason: command);
    }
    // Google Slides: the arrows, B and W, and L, which toggles its laser.
    const slides = BtTarget.googleSlides;
    expect(await key('NEXT', slides), (0, BtKeyMapping.keyRight));
    expect(await key('PREV', slides), (0, BtKeyMapping.keyLeft));
    expect(await key('BLACK_SCREEN', slides), (0, BtKeyMapping.keyB));
    expect(await key('MODE_LASER', slides), (0, BtKeyMapping.keyL));
    expect(await key('LASER_OFF', slides), (0, BtKeyMapping.keyL));
  });

  test('BtTarget.fromName falls back to PowerPoint', () {
    expect(BtTarget.fromName('impress'), BtTarget.impress);
    expect(BtTarget.fromName('wps'), BtTarget.wps);
    expect(BtTarget.fromName(null), BtTarget.powerpoint);
    expect(BtTarget.fromName('bogus'), BtTarget.powerpoint);
  });
}
