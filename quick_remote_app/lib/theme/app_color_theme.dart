import 'package:flutter/material.dart';

import 'app_palette.dart';

/// The color themes of Settings → Theme. Cobalt, the brand's, follows the
/// light/dark mode; the others have one look each. The launcher icon stays
/// Cobalt; the laser and the status colors are the same in all of them.
enum AppColorTheme {
  cobalt(AppPalette.light, AppPalette.dark),
  oled(AppPalette.oled, AppPalette.oled),
  highContrast(AppPalette.highContrast, AppPalette.highContrast),
  mint(AppPalette.mint, AppPalette.mint),
  violet(AppPalette.violet, AppPalette.violet),
  sunset(AppPalette.sunset, AppPalette.sunset);

  const AppColorTheme(this.light, this.dark);

  final AppPalette light;
  final AppPalette dark;

  /// Only Cobalt has a light and a dark look.
  bool get followsMode => this == cobalt;

  /// The mode a theme with one look stands in: Sunset light, the rest dark.
  ThemeMode get fixedMode => dark.isDark ? ThemeMode.dark : ThemeMode.light;

  /// The palette in [brightness] (what the card's preview shows).
  AppPalette paletteFor(Brightness brightness) => brightness == Brightness.dark ? dark : light;

  static AppColorTheme fromName(String? name) =>
      values.firstWhere((t) => t.name == name, orElse: () => cobalt);
}
