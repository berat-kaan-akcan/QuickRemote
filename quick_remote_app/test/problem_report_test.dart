import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:quick_remote_app/app_version.dart';
import 'package:quick_remote_app/l10n/app_localizations.dart';
import 'package:quick_remote_app/l10n/app_localizations_en.dart';
import 'package:quick_remote_app/providers/settings_provider.dart';
import 'package:quick_remote_app/screens/settings/settings_screen.dart';
import 'package:quick_remote_app/services/problem_report.dart';
import 'package:quick_remote_app/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('the issue link carries the version, platform and programs', () {
    final url = ProblemReport.issueUrl(
      AppLocalizationsEn(),
      presenters: 'impress, wps',
      btTarget: 'powerpoint',
    );
    expect(
      url.toString(),
      startsWith('https://github.com/berat-kaan-akcan/QuickRemote/issues/new?'),
    );
    expect(url.queryParameters['title'], '[Android] ');
    final body = url.queryParameters['body']!;
    expect(body, contains('QuickRemote $appVersion'));
    expect(body, contains(Platform.operatingSystem));
    expect(body, contains('impress, wps'));
    expect(body, contains('powerpoint'));
  });

  test('the shared file is named after the day and starts with a header', () {
    expect(
      ProblemReport.fileName(DateTime(2026, 3, 4, 5, 6)),
      'quickremote-log-2026-03-04-0506.txt',
    );
    expect(
      ProblemReport.header(presenters: '-', btTarget: 'wps'),
      startsWith('QuickRemote $appVersion (phone)\n'),
    );
  });

  testWidgets('Ayarlar offers the log, the issue link and the privacy note', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1080, 4000);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => SettingsProvider(),
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
          home: const SettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Share error log'), findsOneWidget);
    expect(find.text('Report a problem'), findsOneWidget);
    expect(find.textContaining('PINs, pairing codes'), findsOneWidget);
  });
}
