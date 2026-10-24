import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:quick_remote_app/l10n/app_localizations.dart';
import 'package:quick_remote_app/models/presentation_analytics.dart';
import 'package:quick_remote_app/providers/settings_provider.dart';
import 'package:quick_remote_app/screens/settings/presentation_history_screen.dart';
import 'package:quick_remote_app/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  PresentationAnalytics record(String id, int day) => PresentationAnalytics(
    id: id,
    startTime: DateTime(2026, 10, day, 10),
    endTime: DateTime(2026, 10, day, 10, 30),
    totalSlideCount: 5,
  );

  // The rows' Dismissibles; a floating SnackBar has one too.
  final rows = find.byWidgetPredicate(
    (w) => w is Dismissible && w.key is ValueKey<String>,
  );

  testWidgets('a swiped record goes at once and Undo puts it back in place', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'language': 'en',
      'presentation_history': jsonEncode([
        record('a', 3).toJson(),
        record('b', 2).toJson(),
        record('c', 1).toJson(),
      ]),
    });
    final settings = SettingsProvider();
    await tester.pumpWidget(
      ChangeNotifierProvider<SettingsProvider>.value(
        value: settings,
        child: MaterialApp(
          theme: AppTheme.dark,
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const PresentationHistoryScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(rows, findsNWidgets(3));

    await tester.drag(find.byKey(const Key('b')).last, const Offset(-600, 0));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(settings.presentationHistory.map((a) => a.id), ['a', 'c']);
    expect(rows, findsNWidgets(2));
    expect(find.text('Presentation record deleted'), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(settings.presentationHistory.map((a) => a.id), ['a', 'b', 'c']);
    expect(rows, findsNWidgets(3));
  });
}
