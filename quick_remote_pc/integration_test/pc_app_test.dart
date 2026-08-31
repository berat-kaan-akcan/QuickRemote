import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter/material.dart';

import 'package:quick_remote_pc/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('PC End-to-End Test', () {
    testWidgets('PC App starts and Home Screen is visible', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Verify app title
      expect(find.text('QuickRemote'), findsWidgets);
      expect(find.text('PC Companion'), findsOneWidget);

      // Verify Start/Stop button
      // Initially, server should be started, so button says "Sunucuyu Durdur", but let's check both possibilities.
      final startStopButtonText = find.byWidgetPredicate(
        (widget) => widget is Text && (widget.data == 'Sunucuyu Başlat' || widget.data == 'Sunucuyu Durdur')
      );
      expect(startStopButtonText, findsOneWidget);

      // We can also find the Start/Stop button by its icon and press it
      // but just verifying the UI renders successfully is enough for this initial integration test
    });
  });
}
