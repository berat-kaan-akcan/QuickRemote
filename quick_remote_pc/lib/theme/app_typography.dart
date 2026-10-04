import 'package:flutter/material.dart';

/// Type scale. Space Grotesk (display) sets headings, the wordmark and
/// figures; Inter (text) sets everything else. Colors come from the theme.
abstract final class AppType {
  static const display = 'SpaceGrotesk';
  static const text = 'Inter';

  static const _tabular = [FontFeature.tabularFigures()];

  /// Big figures: the slide counter, timers, the PIN.
  static const numeric = TextStyle(
    fontFamily: display,
    fontSize: 40,
    height: 1.05,
    fontWeight: FontWeight.w700,
    letterSpacing: -1.2,
    fontFeatures: _tabular,
  );

  static const displayLarge = TextStyle(
    fontFamily: display,
    fontSize: 32,
    height: 1.12,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.9,
  );

  static const headline = TextStyle(
    fontFamily: display,
    fontSize: 24,
    height: 1.2,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
  );

  static const title = TextStyle(
    fontFamily: display,
    fontSize: 19,
    height: 1.25,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.3,
  );

  static const titleSmall = TextStyle(
    fontFamily: text,
    fontSize: 15.5,
    height: 1.3,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.1,
  );

  static const body = TextStyle(
    fontFamily: text,
    fontSize: 15,
    height: 1.45,
    fontWeight: FontWeight.w400,
  );

  static const bodySmall = TextStyle(
    fontFamily: text,
    fontSize: 13,
    height: 1.4,
    fontWeight: FontWeight.w400,
  );

  /// Buttons and tabs.
  static const label = TextStyle(
    fontFamily: text,
    fontSize: 15,
    height: 1.2,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
  );

  static const labelSmall = TextStyle(
    fontFamily: text,
    fontSize: 12.5,
    height: 1.2,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
  );

  /// Section headers above groups of cards.
  static const overline = TextStyle(
    fontFamily: text,
    fontSize: 12,
    height: 1.2,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.6,
  );

  /// Addresses, ports and codes.
  static const mono = TextStyle(
    fontFamily: text,
    fontSize: 12.5,
    height: 1.3,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.2,
    fontFeatures: _tabular,
  );

  static TextTheme textTheme(Color primary, Color secondary) {
    TextStyle c(TextStyle s, Color color) => s.copyWith(color: color);
    return TextTheme(
      displayLarge: c(numeric, primary),
      displayMedium: c(displayLarge, primary),
      displaySmall: c(headline, primary),
      headlineLarge: c(displayLarge, primary),
      headlineMedium: c(headline, primary),
      headlineSmall: c(title.copyWith(fontSize: 21), primary),
      titleLarge: c(title, primary),
      titleMedium: c(titleSmall, primary),
      titleSmall: c(titleSmall.copyWith(fontSize: 14), primary),
      bodyLarge: c(body, primary),
      bodyMedium: c(body.copyWith(fontSize: 14), primary),
      bodySmall: c(bodySmall, secondary),
      labelLarge: c(label, primary),
      labelMedium: c(labelSmall, primary),
      labelSmall: c(labelSmall.copyWith(fontSize: 11), secondary),
    );
  }
}
