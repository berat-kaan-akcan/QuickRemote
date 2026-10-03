import 'package:flutter/widgets.dart';

import 'app_localizations.dart';

export 'app_localizations.dart';

/// The language the user picked; [system] follows the device.
enum AppLanguage {
  system(null),
  tr('tr'),
  en('en');

  const AppLanguage(this.code);

  final String? code;

  /// The language's own name, the same in every UI language.
  String get nativeName => switch (this) {
        system => '',
        tr => 'Türkçe',
        en => 'English',
      };

  Locale? get locale => code == null ? null : Locale(code!);

  static AppLanguage fromCode(String? code) =>
      values.firstWhere((l) => l.code == code, orElse: () => system);
}

/// English first: Flutter falls back to the first supported locale
/// when the device language has no translation.
const supportedAppLocales = [Locale('en'), Locale('tr')];

extension AppLocalizationsContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
