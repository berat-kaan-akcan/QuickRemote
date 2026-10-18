import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quick_remote_app/l10n/app_language.dart';
import 'package:quick_remote_app/providers/settings_provider.dart';
import 'package:quick_remote_app/theme/app_color_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('SettingsProvider initial values', () async {
    final provider = SettingsProvider();

    // allow microtasks to finish since _loadSettings is async
    await Future.delayed(Duration.zero);

    expect(provider.earlyWarningHaptic, true);
    expect(provider.warningVibrations, {
      300: 'double',
      60: 'double',
      30: 'double',
    });
    expect(provider.timeOutVibrationEnabled, true);
    expect(provider.timeOutVibrationPattern, 'triple');
    expect(provider.presentationHistory, isEmpty);
    expect(provider.keepInkOnSlideChange, false);
    expect(provider.language, AppLanguage.system);
  });

  test('SettingsProvider stores the language, system clears it', () async {
    final provider = SettingsProvider();
    await Future.delayed(Duration.zero);
    await provider.setLanguage(AppLanguage.en);

    final reloaded = SettingsProvider();
    await Future.delayed(Duration.zero);
    expect(reloaded.language, AppLanguage.en);

    await reloaded.setLanguage(AppLanguage.system);
    final cleared = SettingsProvider();
    await Future.delayed(Duration.zero);
    expect(cleared.language, AppLanguage.system);
  });

  test('SettingsProvider stores keep ink on slide change', () async {
    final provider = SettingsProvider();
    await Future.delayed(Duration.zero);
    await provider.setKeepInkOnSlideChange(true);
    expect(provider.keepInkOnSlideChange, true);

    final reloaded = SettingsProvider();
    await Future.delayed(Duration.zero);
    expect(reloaded.keepInkOnSlideChange, true);
  });

  test('SettingsProvider stores the color theme and the mode', () async {
    final provider = SettingsProvider();
    await Future.delayed(Duration.zero);
    expect(provider.colorTheme, AppColorTheme.cobalt);
    expect(provider.effectiveThemeMode, ThemeMode.system);

    await provider.setThemeMode(ThemeMode.light);
    await provider.setColorTheme(AppColorTheme.mint);
    // Mint has one look: dark, whatever the mode.
    expect(provider.effectiveThemeMode, ThemeMode.dark);

    final reloaded = SettingsProvider();
    await Future.delayed(Duration.zero);
    expect(reloaded.colorTheme, AppColorTheme.mint);
    expect(reloaded.themeMode, ThemeMode.light);

    await reloaded.setColorTheme(AppColorTheme.sunset);
    expect(reloaded.effectiveThemeMode, ThemeMode.light);
    await reloaded.setColorTheme(AppColorTheme.cobalt);
    expect(reloaded.effectiveThemeMode, ThemeMode.light);
  });

  test('An unknown stored color theme falls back to Cobalt', () async {
    SharedPreferences.setMockInitialValues({'color_theme': 'gone'});
    final provider = SettingsProvider();
    await Future.delayed(Duration.zero);
    expect(provider.colorTheme, AppColorTheme.cobalt);
  });

  test('SettingsProvider updates early warning haptic', () async {
    final provider = SettingsProvider();
    await Future.delayed(Duration.zero);

    await provider.setEarlyWarningHaptic(false);
    expect(provider.earlyWarningHaptic, false);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('early_warning_haptic'), false);
  });

  test('SettingsProvider adds and removes warning time', () async {
    final provider = SettingsProvider();
    await Future.delayed(Duration.zero);

    await provider.addWarningTime(120, pattern: 'single');
    expect(provider.warningVibrations[120], 'single');

    await provider.removeWarningTime(120);
    expect(provider.warningVibrations.containsKey(120), false);
  });
}
