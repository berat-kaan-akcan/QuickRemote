import 'package:flutter/material.dart';

import 'app_palette.dart';

/// Spacing scale, on a 4 px grid.
abstract final class AppSpace {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;

  /// Side padding of a page.
  static const double page = 20;

  /// Widest a phone layout grows on a tablet or in landscape.
  static const double contentMaxWidth = 560;

  /// Smallest touch target (Material and WCAG 2.5.8).
  static const double minTouch = 48;
}

/// Corner radii.
abstract final class AppRadius {
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 28;
  static const double pill = 999;

  static BorderRadius all(double r) => BorderRadius.circular(r);
}

/// Durations and curves. Every animation takes its timing from here, and
/// [AppMotion.of] turns it off when the system asks for less motion.
abstract final class AppMotion {
  /// Press feedback, hover.
  static const fast = Duration(milliseconds: 120);

  /// Toggles, color and size changes.
  static const base = Duration(milliseconds: 220);

  /// Entrances, page content, sheets.
  static const slow = Duration(milliseconds: 380);

  /// Route transitions.
  static const page = Duration(milliseconds: 320);

  /// Delay between items of a staggered entrance.
  static const stagger = Duration(milliseconds: 45);

  static const standard = Cubic(0.2, 0, 0, 1); // Material 3 emphasized
  static const enter = Curves.easeOutCubic;
  static const exit = Curves.easeInCubic;
  static const press = Curves.easeOutQuad;

  /// Whether the user turned animations off (Android "Remove animations").
  static bool reduced(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  /// [d], or no time at all when motion is reduced.
  static Duration of(BuildContext context, Duration d) =>
      reduced(context) ? Duration.zero : d;
}

/// Elevation as soft, tinted shadows (the theme has no Material elevation).
abstract final class AppShadows {
  /// Cards resting on the page.
  static List<BoxShadow> soft(AppPalette p) => [
        BoxShadow(
          color: p.shadow,
          blurRadius: p.isDark ? 24 : 18,
          offset: const Offset(0, 8),
          spreadRadius: -6,
        ),
      ];

  /// Sheets, dialogs, the floating navigation bar.
  static List<BoxShadow> raised(AppPalette p) => [
        BoxShadow(
          color: p.shadow,
          blurRadius: 32,
          offset: const Offset(0, 12),
          spreadRadius: -8,
        ),
      ];

  /// A colored halo under a primary button or a lit element.
  static List<BoxShadow> glow(Color color, {double strength = 1}) => [
        BoxShadow(
          color: color.withValues(alpha: 0.35 * strength),
          blurRadius: 24 * strength,
          offset: Offset(0, 8 * strength),
          spreadRadius: -6,
        ),
      ];
}
