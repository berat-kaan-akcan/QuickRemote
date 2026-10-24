import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:quick_remote_pc/l10n/app_language.dart';
import 'package:quick_remote_pc/providers/appearance_provider.dart';
import 'package:quick_remote_pc/providers/language_provider.dart';
import 'package:quick_remote_pc/providers/laser_overlay_provider.dart';
import 'package:quick_remote_pc/screens/home/widgets/laser_setting_section.dart';
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

    await tester.ensureVisible(find.text('Always QuickRemote’s laser'));
    await tester.tap(find.text('Always QuickRemote’s laser'));
    await tester.pumpAndSettle();
    expect(LaserOverlaySettings.mode, LaserOverlayMode.always);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('laser_overlay'), 'always');
    LaserOverlaySettings.mode = LaserOverlayMode.auto;
  }, skip: !(Platform.isLinux || Platform.isWindows));

  testWidgets('the laser choices and their table fit the narrow window', (tester) async {
    tester.view.physicalSize = const Size(440, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final language = LanguageProvider();
    await language.setLanguage(AppLanguage.tr);
    await tester.pumpWidget(_app(language));
    await tester.pumpAndSettle();

    expect(find.text('Otomatik (önerilen)'), findsOneWidget);
    expect(find.text('Sunum programının kendi lazeri'), findsOneWidget);
    expect(find.text('Gösteri dışında'), findsOneWidget);
    expect(tester.takeException(), isNull);
  }, skip: !(Platform.isLinux || Platform.isWindows));

  test('the table says whose laser shows where, as the overlay decides', () {
    LaserDrawer at(LaserOverlayMode mode, LaserPlace place) => laserDrawer(mode, place);
    expect(at(LaserOverlayMode.auto, LaserPlace.powerPoint), LaserDrawer.program);
    expect(at(LaserOverlayMode.auto, LaserPlace.wps), LaserDrawer.program);
    expect(at(LaserOverlayMode.auto, LaserPlace.impress), LaserDrawer.quickRemote);
    expect(at(LaserOverlayMode.auto, LaserPlace.pdf), LaserDrawer.quickRemote);
    expect(at(LaserOverlayMode.auto, LaserPlace.outsideShow), LaserDrawer.quickRemote);
    for (final place in LaserPlace.values) {
      expect(at(LaserOverlayMode.always, place), LaserDrawer.quickRemote);
    }
    expect(at(LaserOverlayMode.never, LaserPlace.impress), LaserDrawer.program);
    expect(at(LaserOverlayMode.never, LaserPlace.pdf), LaserDrawer.none);
    expect(at(LaserOverlayMode.never, LaserPlace.outsideShow), LaserDrawer.none);
  });
}
