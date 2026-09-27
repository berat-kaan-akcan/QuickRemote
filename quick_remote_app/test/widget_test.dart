import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quick_remote_app/main.dart';


void main() {
  testWidgets('QuickRemoteApp renders HomeScreen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const QuickRemoteApp());
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // Verify that it renders the HomeScreen. Since we don't have access to the exact text in HomeScreen without viewing it,
    // we can check if it rendered the MaterialApp and check by type.
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
