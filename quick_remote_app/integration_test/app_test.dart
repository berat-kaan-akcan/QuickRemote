import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter/material.dart';

import 'package:quick_remote_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('End-to-End Test', () {
    testWidgets('App starts and Home Screen is visible', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Verify Home Screen title
      expect(find.text('QuickRemote'), findsWidgets);
      expect(find.text('Sunumlarınızı telefondan kontrol edin'), findsOneWidget);

      // Verify Connect button
      expect(find.text('QR Kod ile Bağlan'), findsOneWidget);

      // Verify Settings button exists (it's an IconButton with settings icon)
      final settingsButton = find.byIcon(Icons.settings_rounded);
      expect(settingsButton, findsOneWidget);

      // Tap Settings button and verify transition
      await tester.tap(settingsButton);
      await tester.pumpAndSettle();

      // Verify we are in Settings Screen
      // The settings screen has an AppBar with title 'Ayarlar'
      expect(find.text('Ayarlar'), findsWidgets);
      
      // Go back to Home Screen
      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.text('QR Kod ile Bağlan'), findsOneWidget);
    });
  });
}
