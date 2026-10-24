import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quick_remote_app/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final cases = <(String, Size, double)>[
    ('phone, text 2.0', const Size(360, 640), 2.0),
    ('small phone, text 2.0', const Size(320, 568), 2.0),
    ('landscape phone', const Size(640, 360), 1.0),
    ('landscape phone, text 1.5', const Size(640, 360), 1.5),
    ('tablet', const Size(800, 1280), 1.0),
    ('foldable cover screen', const Size(280, 653), 1.3),
  ];
  for (final lang in ['tr', 'en']) {
    for (final (name, size, scale) in cases) {
      testWidgets('home ($lang): $name has no overflow, first-run buttons reachable', (tester) async {
        SharedPreferences.setMockInitialValues({'language': lang});
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final handle = tester.ensureSemantics();

        await tester.pumpWidget(const QuickRemoteApp());
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        expect(tester.takeException(), isNull);
        final scan = find.text(lang == 'tr' ? 'QR Kod ile Bağlan' : 'Connect with QR Code');
        expect(scan, findsOneWidget);
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        handle.dispose();
      });
    }
  }
}
