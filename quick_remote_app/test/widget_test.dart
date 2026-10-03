import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quick_remote_app/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('QuickRemoteApp renders HomeScreen', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const QuickRemoteApp());
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('the picked language is used', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'language': 'en'});
    await tester.pumpWidget(const QuickRemoteApp());
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Connect with QR Code'), findsOneWidget);
  });

  testWidgets('Turkish shows Turkish texts', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'language': 'tr'});
    await tester.pumpWidget(const QuickRemoteApp());
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('QR Kod ile Bağlan'), findsOneWidget);
  });
}
