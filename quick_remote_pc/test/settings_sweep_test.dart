import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:quick_remote_pc/l10n/app_language.dart';
import 'package:quick_remote_pc/providers/appearance_provider.dart';
import 'package:quick_remote_pc/providers/language_provider.dart';
import 'package:quick_remote_pc/providers/laser_overlay_provider.dart';
import 'package:quick_remote_pc/screens/home/widgets/settings_dialog.dart';
import 'package:quick_remote_pc/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _app(LanguageProvider language, [AppearanceProvider? appearance]) => MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: language),
        ChangeNotifierProvider.value(value: appearance ?? AppearanceProvider()),
        ChangeNotifierProvider(create: (_) => LaserOverlayProvider()),
      ],
      child: Consumer2<LanguageProvider, AppearanceProvider>(
        builder: (context, language, appearance, _) => MaterialApp(
          locale: language.language.locale,
          themeMode: appearance.mode,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          supportedLocales: supportedAppLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder: (c, child) => MediaQuery(data: MediaQuery.of(c).copyWith(textScaler: TextScaler.linear(_scale)), child: child!),
          home: const Scaffold(body: SettingsDialog()),
        ),
      ),
    );


double _scale = 1;

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  for (final lang in [AppLanguage.tr, AppLanguage.en]) {
    for (final (name, size, scale) in [
      ('opening size', const Size(440, 760), 1.0),
      ('opening size, text 2.0', const Size(440, 760), 2.0),
      ('small window', const Size(380, 420), 1.0),
      ('small window, text 1.5', const Size(380, 420), 1.5),
    ]) {
      testWidgets('settings (${lang.name}) at $name: no overflow, labeled', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        _scale = scale;
        final handle = tester.ensureSemantics();
        final language = LanguageProvider();
        await language.setLanguage(lang);
        await tester.pumpWidget(_app(language));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        handle.dispose();
      });
    }
  }

  testWidgets('settings shows the version and opens the license page', (tester) async {
    tester.view.physicalSize = const Size(440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    _scale = 1;
    final language = LanguageProvider();
    await language.setLanguage(AppLanguage.en);
    await tester.pumpWidget(_app(language));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Open-source licenses'));
    await tester.pumpAndSettle();
    expect(find.textContaining('QuickRemote PC 0.'), findsOneWidget);
    await tester.tap(find.text('Open-source licenses'));
    await tester.pumpAndSettle();
    expect(find.byType(LicensePage), findsOneWidget);
  });
}
