import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:quick_remote_pc/app_version.dart';
import 'package:quick_remote_pc/l10n/app_language.dart';
import 'package:quick_remote_pc/l10n/app_localizations_en.dart';
import 'package:quick_remote_pc/providers/appearance_provider.dart';
import 'package:quick_remote_pc/providers/language_provider.dart';
import 'package:quick_remote_pc/providers/laser_overlay_provider.dart';
import 'package:quick_remote_pc/screens/home/widgets/settings_dialog.dart';
import 'package:quick_remote_pc/services/desktop/problem_report.dart';
import 'package:quick_remote_pc/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('the issue link carries the version, platform and programs', () {
    final url = ProblemReport.issueUrl(AppLocalizationsEn());
    expect(
      url.toString(),
      startsWith('https://github.com/berat-kaan-akcan/QuickRemote/issues/new?'),
    );
    expect(url.queryParameters['title'], '[PC] ');
    final body = url.queryParameters['body']!;
    expect(body, contains('QuickRemote PC $appVersion'));
    expect(body, contains(Platform.operatingSystem));
    expect(body, contains(ProblemReport.presenters));
  });

  test('the exported file is named after the day', () {
    expect(
      ProblemReport.fileName(DateTime(2026, 3, 4, 5, 6)),
      'quickremote-pc-log-2026-03-04-0506.txt',
    );
    expect(ProblemReport.header, startsWith('QuickRemote PC $appVersion\n'));
  });

  testWidgets(
    'Settings offers the log export, the issue link and the privacy note',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final language = LanguageProvider();
      await language.setLanguage(AppLanguage.tr);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: language),
            ChangeNotifierProvider(create: (_) => AppearanceProvider()),
            ChangeNotifierProvider(create: (_) => LaserOverlayProvider()),
          ],
          child: MaterialApp(
            locale: const Locale('tr'),
            theme: AppTheme.light,
            supportedLocales: supportedAppLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: const Scaffold(body: SettingsDialog()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Günlüğü dışa aktar'), findsOneWidget);
      expect(find.text('Sorun bildir'), findsOneWidget);
      expect(find.textContaining('PIN'), findsWidgets);
    },
  );
}
