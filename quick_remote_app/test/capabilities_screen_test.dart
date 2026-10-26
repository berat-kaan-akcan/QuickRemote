import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:quick_remote_app/l10n/app_localizations.dart';
import 'package:quick_remote_app/screens/settings/capabilities_screen.dart';
import 'package:quick_remote_app/screens/settings/capability_table.dart';
import 'package:quick_remote_app/services/websocket_service.dart';
import 'package:quick_remote_app/theme/app_theme.dart';

class _Ws extends WebSocketService {
  _Ws({String? platform}) {
    if (platform != null) {
      handleMessage({'type': 'auth', 'status': 'ok', 'platform': platform});
    }
  }
}

void main() {
  test('every program offered has every feature', () {
    for (final link in CapLink.values) {
      for (final os in CapOs.values) {
        final programs = CapabilityTable.programs(link, os);
        expect(programs, isNotEmpty);
        for (final program in programs) {
          for (final feature in CapFeature.values) {
            expect(
              () => CapabilityTable.cell(link, os, program, feature),
              returnsNormally,
              reason: '$link $os $program $feature',
            );
          }
        }
      }
    }
  });

  test('Bluetooth shows the programs the phone has keys for', () {
    for (final os in CapOs.values) {
      expect(CapabilityTable.programs(CapLink.bluetooth, os), [
        CapProgram.powerpoint,
        CapProgram.impress,
        CapProgram.wps,
        CapProgram.powerpointWeb,
        CapProgram.googleSlides,
      ]);
    }
    final eraser = CapabilityTable.cell(
      CapLink.bluetooth,
      CapOs.windows,
      CapProgram.wps,
      CapFeature.eraser,
    );
    expect(eraser.level, CapLevel.partial);
    expect(
      CapabilityTable.cell(
        CapLink.bluetooth,
        CapOs.linux,
        CapProgram.wps,
        CapFeature.eraser,
      ).level,
      CapLevel.yes,
    );
  });

  Future<void> pumpScreen(
    WidgetTester tester, {
    String? platform,
    double width = 360,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = Size(width, 2400);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ChangeNotifierProvider<WebSocketService>.value(
        value: _Ws(platform: platform),
        child: MaterialApp(
          theme: AppTheme.dark,
          locale: const Locale('tr'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const CapabilitiesScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('opens on the connected PC\'s system and switches programs', (
    tester,
  ) async {
    await pumpScreen(tester, platform: 'linux');
    expect(find.text('Impress'), findsOneWidget);
    expect(find.text('WPS (kendin açtığın)'), findsOneWidget);
    expect(find.text('Gösteri ilk slayttan başlar.'), findsNothing);

    await tester.tap(find.text('WPS (kendin açtığın)'));
    await tester.pumpAndSettle();
    expect(find.text('Gösteri ilk slayttan başlar.'), findsOneWidget);

    // Bluetooth has no "own WPS": the first program is shown instead.
    await tester.tap(find.text('Bluetooth'));
    await tester.pumpAndSettle();
    expect(find.text('PowerPoint'), findsOneWidget);
    expect(
      find.text('Bluetooth\'ta bilgisayar telefona bilgi göndermez.'),
      findsWidgets,
    );
  });

  testWidgets('the compare table fits a narrow phone with four programs', (
    tester,
  ) async {
    await pumpScreen(tester, platform: 'linux', width: 320);
    await tester.tap(find.text('Karşılaştır'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('PDF'), findsOneWidget);
    expect(find.text('Sonraki / önceki slayt'), findsOneWidget);
  });

  test('only cells that work at least partly are marked untried', () {
    for (final link in CapLink.values) {
      for (final os in CapOs.values) {
        for (final program in CapabilityTable.programs(link, os)) {
          for (final feature in CapFeature.values) {
            if (!CapabilityTable.untried(link, os, program, feature)) continue;
            expect(
              CapabilityTable.cell(link, os, program, feature).level,
              isNot(CapLevel.no),
              reason: '$link $os $program $feature',
            );
          }
        }
      }
    }
  });

  testWidgets('features not tried on a device carry a tag', (tester) async {
    await pumpScreen(tester, platform: 'windows');
    expect(find.text('PowerPoint'), findsOneWidget);
    // The eraser, the slide picture, slide media and volume of PowerPoint.
    expect(find.text('Denenmedi'), findsNWidgets(4 + 1));
    expect(
      find.textContaining('gerçek bir cihazda henüz denenmedi'),
      findsOneWidget,
    );
  });
}
