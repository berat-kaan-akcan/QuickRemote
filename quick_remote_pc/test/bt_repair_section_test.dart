import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quick_remote_pc/l10n/app_localizations.dart';
import 'package:quick_remote_pc/screens/home/widgets/bt_repair_section.dart';
import 'package:quick_remote_pc/services/desktop/bluetooth_pairing.dart';
import 'package:quick_remote_pc/theme/app_theme.dart';

const _phone = PairedDevice(name: 'Galaxy S23 FE', address: 0xA1B2C3D4E5F6, classOfDevice: 0x5A020C);
const _headset = PairedDevice(name: 'Buds', address: 0x010203040506, classOfDevice: 0x240404);
const _oldPhone = PairedDevice(name: 'a52', address: 0x0A0B0C0D0E0F, classOfDevice: 0x5A020C);
const _nameless = PairedDevice(name: ' ', address: 0x111213141516, classOfDevice: 0);

class _FakePairing implements BluetoothPairing {
  _FakePairing(this.devices, {this.removes = true, this.opens = true});

  final List<PairedDevice> devices;
  final bool removes;
  final bool opens;
  final log = <String>[];

  @override
  List<PairedDevice> paired() => devices;

  @override
  bool remove(PairedDevice device) {
    log.add('remove ${device.addressText}');
    return removes;
  }

  @override
  Future<bool> openSettings() async {
    log.add('settings');
    return opens;
  }
}

Future<void> _pick(WidgetTester tester, String name) async {
  await tester.tap(find.text('Pair the phone again'));
  await tester.pumpAndSettle();
  await tester.tap(find.text(name));
  await tester.pumpAndSettle();
}

Widget _app(Widget child) => MaterialApp(
      theme: AppTheme.light,
      locale: const Locale('en'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );

void main() {
  test('a phone is told by its Class of Device, the address as Windows shows it', () {
    expect(_phone.isPhone, isTrue);
    expect(_headset.isPhone, isFalse);
    expect(_phone.addressText, 'A1:B2:C3:D4:E5:F6');
    expect(_nameless.label, '11:12:13:14:15:16');
  });

  group('BtRepair', () {
    test('lists phones first, then by name whatever the case', () {
      final repair = BtRepair(_FakePairing(const [_nameless, _headset, _phone, _oldPhone]));
      expect(repair.candidates(), [_oldPhone, _phone, _nameless, _headset]);
    });

    test('removes the device, then opens the settings', () async {
      final pairing = _FakePairing(const [_phone]);
      expect(await BtRepair(pairing).repair(_phone), BtRepairOutcome.removed);
      expect(pairing.log, ['remove A1:B2:C3:D4:E5:F6', 'settings']);
    });

    test('a device Windows keeps is not followed by the settings', () async {
      final pairing = _FakePairing(const [_phone], removes: false);
      expect(await BtRepair(pairing).repair(_phone), BtRepairOutcome.removeFailed);
      expect(pairing.log, ['remove A1:B2:C3:D4:E5:F6']);
    });

    test('settings that do not open are told apart', () async {
      final pairing = _FakePairing(const [_phone], opens: false);
      expect(await BtRepair(pairing).repair(_phone), BtRepairOutcome.removedSettingsClosed);
    });
  });

  testWidgets('removes the phone picked, then says to add it again', (tester) async {
    final pairing = _FakePairing(const [_phone, _headset]);
    await tester.pumpWidget(_app(BtRepairSection(pairing: pairing)));
    await tester.tap(find.text('Pair the phone again'));
    await tester.pumpAndSettle();
    expect(find.text('Buds'), findsOneWidget);
    await tester.tap(find.text('Galaxy S23 FE'));
    await tester.pumpAndSettle();
    expect(pairing.log, ['remove A1:B2:C3:D4:E5:F6', 'settings']);
    expect(find.textContaining('Galaxy S23 FE was removed. Add the phone again'), findsOneWidget);
  });

  testWidgets('a refusal says so and opens nothing', (tester) async {
    final pairing = _FakePairing(const [_phone], removes: false);
    await tester.pumpWidget(_app(BtRepairSection(pairing: pairing)));
    await _pick(tester, 'Galaxy S23 FE');
    expect(pairing.log, isNot(contains('settings')));
    expect(find.textContaining('could not be removed'), findsOneWidget);
  });

  testWidgets('settings that did not open: the user is told to open them', (tester) async {
    await tester.pumpWidget(_app(BtRepairSection(pairing: _FakePairing(const [_phone], opens: false))));
    await _pick(tester, 'Galaxy S23 FE');
    expect(find.textContaining("Open Windows' Bluetooth settings"), findsOneWidget);
  });

  testWidgets('closing the dialog removes nothing', (tester) async {
    final pairing = _FakePairing(const [_phone]);
    await tester.pumpWidget(_app(BtRepairSection(pairing: pairing)));
    await tester.tap(find.text('Pair the phone again'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(pairing.log, isEmpty);
  });

  testWidgets('without paired devices the dialog says how to add one', (tester) async {
    await tester.pumpWidget(_app(BtRepairSection(pairing: _FakePairing(const []))));
    await tester.tap(find.text('Pair the phone again'));
    await tester.pumpAndSettle();
    expect(find.textContaining('No Bluetooth device is paired'), findsOneWidget);
  });
}
