import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quick_remote_app/l10n/app_localizations.dart';
import 'package:quick_remote_app/screens/home/widgets/connect_buttons.dart';
import 'package:quick_remote_app/theme/app_theme.dart';

void main() {
  Future<List<String>> pumpDock(
    WidgetTester tester, {
    bool connecting = false,
  }) async {
    final taps = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: ConnectDock(
              connecting: connecting,
              onScan: () => taps.add('scan'),
              onBluetooth: () => taps.add('bluetooth'),
              onManual: () => taps.add('manual'),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    return taps;
  }

  testWidgets('the QR key and the manual tile connect', (tester) async {
    final taps = await pumpDock(tester);

    expect(find.byIcon(Icons.arrow_forward_rounded), findsOneWidget);
    await tester.tap(find.text('Connect with QR Code'));
    await tester.tap(find.text('Manual connection'));
    expect(taps, ['scan', 'manual']);
  });

  testWidgets('while connecting the QR key is locked and says so', (
    tester,
  ) async {
    final taps = await pumpDock(tester, connecting: true);

    expect(find.text('Connecting...'), findsOneWidget);
    expect(find.text('Connect with QR Code'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.tap(find.text('Connecting...'));
    await tester.tap(find.text('Manual connection'));
    expect(taps, isEmpty);
  });
}
