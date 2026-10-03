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

  test('WPS uses the arrow for the laser and has no eraser key', () async {
    expect(await keyReport('MODE_PEN', BtTarget.wps), (ctrl, BtKeyMapping.keyP));
    calls.clear();
    expect(await keyReport('MODE_HIGHLIGHTER', BtTarget.wps), (ctrl, BtKeyMapping.keyI));
    calls.clear();
    // Ctrl+L moves WPS's show: the "laser" is the arrow pointer.
    expect(await keyReport('MODE_LASER', BtTarget.wps), (ctrl, BtKeyMapping.keyA));
    calls.clear();
    expect(await keyReport('ERASE_ALL', BtTarget.wps), (0, BtKeyMapping.keyE));
    calls.clear();
    expect(await keyReport('MODE_ERASER', BtTarget.wps), isNull);
  });

  test('BtTarget.fromName falls back to PowerPoint', () {
    expect(BtTarget.fromName('impress'), BtTarget.impress);
    expect(BtTarget.fromName('wps'), BtTarget.wps);
    expect(BtTarget.fromName(null), BtTarget.powerpoint);
    expect(BtTarget.fromName('bogus'), BtTarget.powerpoint);
  });
}
