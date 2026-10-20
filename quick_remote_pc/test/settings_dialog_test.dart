import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:quick_remote_pc/l10n/app_language.dart';
import 'package:quick_remote_pc/providers/appearance_provider.dart';
import 'package:quick_remote_pc/providers/language_provider.dart';
import 'package:quick_remote_pc/providers/laser_overlay_provider.dart';
import 'package:quick_remote_pc/screens/home/widgets/settings_dialog.dart';
import 'package:quick_remote_pc/services/overlay/laser_overlay.dart';
import 'package:quick_remote_pc/theme/app_palette.dart';
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
          home: const Scaffold(body: SettingsDialog()),
        ),
      ),
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('picking a language switches the UI at once', (tester) async {
    final language = LanguageProvider();
    await language.setLanguage(AppLanguage.tr);
    await tester.pumpWidget(_app(language));
    await tester.pumpAndSettle();
    expect(find.text('Ayarlar'), findsOneWidget);

    await tester.tap(find.byType(DropdownButton<AppLanguage>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('English').last);
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsOneWidget);
    expect(language.language, AppLanguage.en);
  });

  testWidgets('picking Light switches the window to the light palette', (tester) async {
    final language = LanguageProvider();
    await language.setLanguage(AppLanguage.tr);
    final appearance = AppearanceProvider();
    await appearance.setMode(ThemeMode.dark);
    await tester.pumpWidget(_app(language, appearance));
    await tester.pumpAndSettle();
    AppPalette palette() => Theme.of(tester.element(find.text('Ayarlar'))).extension<AppPalette>()!;
    expect(palette().isDark, isTrue);

    await tester.tap(find.text('Açık'));
    await tester.pumpAndSettle();
    expect(appearance.mode, ThemeMode.light);
    expect(palette().isDark, isFalse);
  });

  testWidgets('picking who draws the laser stores it', (tester) async {
    final language = LanguageProvider();
    await language.setLanguage(AppLanguage.en);
    await tester.pumpWidget(_app(language));
    await tester.pumpAndSettle();
    expect(LaserOverlaySettings.mode, LaserOverlayMode.auto);

    await tester.ensureVisible(find.text('QuickRemote'));
    await tester.tap(find.text('QuickRemote'));
    await tester.pumpAndSettle();
    expect(LaserOverlaySettings.mode, LaserOverlayMode.always);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('laser_overlay'), 'always');
    LaserOverlaySettings.mode = LaserOverlayMode.auto;
  }, skip: !Platform.isLinux); // the overlay is Linux-only so far
}
