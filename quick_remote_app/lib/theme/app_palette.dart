import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Semantic colors of the current theme. Read them with `context.palette`.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.isDark,
    required this.background,
    required this.surface,
    required this.surfaceRaised,
    required this.surfaceSunken,
    required this.border,
    required this.borderStrong,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.primary,
    required this.primaryBright,
    required this.primaryDeep,
    required this.onPrimary,
    required this.primaryText,
    required this.accent,
    required this.accentText,
    required this.success,
    required this.onSuccess,
    required this.warning,
    required this.onWarning,
    required this.danger,
    required this.onDanger,
    required this.info,
    required this.onInfo,
    required this.violetText,
    required this.toolLaser,
    required this.toolPen,
    required this.toolHighlighter,
    required this.glass,
    required this.glassBorder,
    required this.shadow,
    required this.scrim,
  });

  final bool isDark;

  final Color background;
  final Color surface;

  /// Cards that sit above a [surface], sheets and dialogs.
  final Color surfaceRaised;

  /// Inputs, tracks and wells.
  final Color surfaceSunken;
  final Color border;
  final Color borderStrong;

  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;

  /// Fill of primary buttons, with [primaryBright] as its gradient end.
  final Color primary;
  final Color primaryBright;

  /// The dark end of the large Next key's gradient.
  final Color primaryDeep;
  final Color onPrimary;

  /// Primary as text or an icon on [background] or [surface].
  final Color primaryText;

  /// The laser accent, as a fill or glow; [accentText] as text.
  final Color accent;
  final Color accentText;

  final Color success;
  final Color onSuccess;
  final Color warning;
  final Color onWarning;
  final Color danger;
  final Color onDanger;
  final Color info;
  final Color onInfo;

  /// Violet as an icon on [surface]: the Theme row's badge.
  final Color violetText;

  final Color toolLaser;
  final Color toolPen;
  final Color toolHighlighter;

  /// Translucent fill and edge of glass panels.
  final Color glass;
  final Color glassBorder;
  final Color shadow;
  final Color scrim;

  /// The eraser tool is neutral: it takes ink away.
  Color get toolEraser => textSecondary;

  static const light = AppPalette(
    isDark: false,
    background: AppColors.paper,
    surface: AppColors.paperSurface,
    surfaceRaised: AppColors.paperSurface,
    surfaceSunken: AppColors.paperSunken,
    border: AppColors.paperBorder,
    borderStrong: AppColors.paperBorderStrong,
    textPrimary: AppColors.inkText,
    textSecondary: AppColors.inkTextSecondary,
    textMuted: AppColors.inkTextMuted,
    primary: AppColors.cobalt,
    primaryBright: AppColors.cobaltBright,
    primaryDeep: AppColors.cobaltDeep,
    onPrimary: AppColors.white,
    primaryText: AppColors.cobalt,
    accent: AppColors.laser,
    accentText: AppColors.laserDeep,
    success: AppColors.successDeep,
    onSuccess: AppColors.white,
    warning: AppColors.warningDeep,
    onWarning: AppColors.white,
    danger: AppColors.dangerDeep,
    onDanger: AppColors.white,
    info: AppColors.infoDeep,
    onInfo: AppColors.white,
    violetText: AppColors.violetPrimary,
    toolLaser: AppColors.toolLaserDeep,
    toolPen: AppColors.toolPenDeep,
    toolHighlighter: AppColors.toolHighlighterDeep,
    glass: AppColors.paperGlass,
    glassBorder: AppColors.paperGlassBorder,
    shadow: AppColors.paperShadow,
    scrim: AppColors.paperScrim,
  );

  static const dark = AppPalette(
    isDark: true,
    background: AppColors.ink,
    surface: AppColors.inkSurface,
    surfaceRaised: AppColors.inkRaised,
    surfaceSunken: AppColors.inkSunken,
    border: AppColors.inkBorder,
    borderStrong: AppColors.inkBorderStrong,
    textPrimary: AppColors.paperText,
    textSecondary: AppColors.paperTextSecondary,
    textMuted: AppColors.paperTextMuted,
    primary: AppColors.cobalt,
    primaryBright: AppColors.cobaltBright,
    primaryDeep: AppColors.cobaltDeep,
    onPrimary: AppColors.white,
    primaryText: AppColors.cobaltLight,
    accent: AppColors.laser,
    accentText: AppColors.laser,
    success: AppColors.success,
    onSuccess: AppColors.ink,
    warning: AppColors.warning,
    onWarning: AppColors.ink,
    danger: AppColors.danger,
    onDanger: AppColors.ink,
    info: AppColors.info,
    onInfo: AppColors.ink,
    violetText: AppColors.violetPrimaryText,
    toolLaser: AppColors.toolLaser,
    toolPen: AppColors.toolPen,
    toolHighlighter: AppColors.toolHighlighter,
    glass: AppColors.inkGlass,
    glassBorder: AppColors.inkGlassBorder,
    shadow: AppColors.inkShadow,
    scrim: AppColors.inkScrim,
  );

  /// OLED: black and white, the fewest lit pixels in a dark room.
  static const oled = AppPalette(
    isDark: true,
    background: AppColors.oledBackground,
    surface: AppColors.oledSurface,
    surfaceRaised: AppColors.oledRaised,
    surfaceSunken: AppColors.oledSunken,
    border: AppColors.oledBorder,
    borderStrong: AppColors.oledBorderStrong,
    textPrimary: AppColors.oledText,
    textSecondary: AppColors.oledTextSecondary,
    textMuted: AppColors.oledTextMuted,
    primary: AppColors.oledPrimary,
    primaryBright: AppColors.oledPrimaryBright,
    primaryDeep: AppColors.oledPrimaryDeep,
    onPrimary: AppColors.black,
    primaryText: AppColors.oledText,
    accent: AppColors.laser,
    accentText: AppColors.laser,
    success: AppColors.success,
    onSuccess: AppColors.ink,
    warning: AppColors.warning,
    onWarning: AppColors.ink,
    danger: AppColors.danger,
    onDanger: AppColors.ink,
    info: AppColors.info,
    onInfo: AppColors.ink,
    violetText: AppColors.violetPrimaryText,
    toolLaser: AppColors.toolLaser,
    toolPen: AppColors.toolPen,
    toolHighlighter: AppColors.toolHighlighter,
    glass: AppColors.inkGlass,
    glassBorder: AppColors.inkGlassBorder,
    shadow: AppColors.inkShadow,
    scrim: AppColors.inkScrim,
  );

  /// Yellow on black: the most legible in sunlight and for weak eyes.
  static const highContrast = AppPalette(
    isDark: true,
    background: AppColors.contrastBackground,
    surface: AppColors.contrastSurface,
    surfaceRaised: AppColors.contrastRaised,
    surfaceSunken: AppColors.contrastSunken,
    border: AppColors.contrastBorder,
    borderStrong: AppColors.contrastBorderStrong,
    textPrimary: AppColors.contrastText,
    textSecondary: AppColors.contrastTextSecondary,
    textMuted: AppColors.contrastTextMuted,
    primary: AppColors.contrastPrimary,
    primaryBright: AppColors.contrastPrimaryBright,
    primaryDeep: AppColors.contrastPrimaryDeep,
    onPrimary: AppColors.black,
    primaryText: AppColors.contrastPrimary,
    accent: AppColors.laser,
    accentText: AppColors.laser,
    success: AppColors.success,
    onSuccess: AppColors.ink,
    warning: AppColors.warning,
    onWarning: AppColors.ink,
    danger: AppColors.danger,
    onDanger: AppColors.ink,
    info: AppColors.info,
    onInfo: AppColors.ink,
    violetText: AppColors.violetPrimaryText,
    toolLaser: AppColors.toolLaser,
    toolPen: AppColors.toolPen,
    toolHighlighter: AppColors.toolHighlighter,
    glass: AppColors.inkGlass,
    glassBorder: AppColors.inkGlassBorder,
    shadow: AppColors.inkShadow,
    scrim: AppColors.inkScrim,
  );

  /// Calm green on a dark sea.
  static const mint = AppPalette(
    isDark: true,
    background: AppColors.mintBackground,
    surface: AppColors.mintSurface,
    surfaceRaised: AppColors.mintRaised,
    surfaceSunken: AppColors.mintSunken,
    border: AppColors.mintBorder,
    borderStrong: AppColors.mintBorderStrong,
    textPrimary: AppColors.mintText,
    textSecondary: AppColors.mintTextSecondary,
    textMuted: AppColors.mintTextMuted,
    primary: AppColors.mintPrimary,
    primaryBright: AppColors.mintPrimaryBright,
    primaryDeep: AppColors.mintPrimaryDeep,
    onPrimary: AppColors.mintOnPrimary,
    primaryText: AppColors.mintPrimaryBright,
    accent: AppColors.laser,
    accentText: AppColors.laser,
    success: AppColors.success,
    onSuccess: AppColors.ink,
    warning: AppColors.warning,
    onWarning: AppColors.ink,
    danger: AppColors.danger,
    onDanger: AppColors.ink,
    info: AppColors.info,
    onInfo: AppColors.ink,
    violetText: AppColors.violetPrimaryText,
    toolLaser: AppColors.toolLaser,
    toolPen: AppColors.toolPen,
    toolHighlighter: AppColors.toolHighlighter,
    glass: AppColors.inkGlass,
    glassBorder: AppColors.inkGlassBorder,
    shadow: AppColors.inkShadow,
    scrim: AppColors.inkScrim,
  );

  /// Lively violet on a night purple.
  static const violet = AppPalette(
    isDark: true,
    background: AppColors.violetBackground,
    surface: AppColors.violetSurface,
    surfaceRaised: AppColors.violetRaised,
    surfaceSunken: AppColors.violetSunken,
    border: AppColors.violetBorder,
    borderStrong: AppColors.violetBorderStrong,
    textPrimary: AppColors.violetText,
    textSecondary: AppColors.violetTextSecondary,
    textMuted: AppColors.violetTextMuted,
    primary: AppColors.violetPrimary,
    primaryBright: AppColors.violetPrimaryBright,
    primaryDeep: AppColors.violetPrimaryDeep,
    onPrimary: AppColors.white,
    primaryText: AppColors.violetPrimaryText,
    accent: AppColors.laser,
    accentText: AppColors.laser,
    success: AppColors.success,
    onSuccess: AppColors.ink,
    warning: AppColors.warning,
    onWarning: AppColors.ink,
    danger: AppColors.danger,
    onDanger: AppColors.ink,
    info: AppColors.info,
    onInfo: AppColors.ink,
    violetText: AppColors.violetPrimaryText,
    toolLaser: AppColors.toolLaser,
    toolPen: AppColors.toolPen,
    toolHighlighter: AppColors.toolHighlighter,
    glass: AppColors.inkGlass,
    glassBorder: AppColors.inkGlassBorder,
    shadow: AppColors.inkShadow,
    scrim: AppColors.inkScrim,
  );

  /// Cream and terracotta: the second light theme, light only.
  static const sunset = AppPalette(
    isDark: false,
    background: AppColors.sunsetBackground,
    surface: AppColors.sunsetSurface,
    surfaceRaised: AppColors.sunsetSurface,
    surfaceSunken: AppColors.sunsetSunken,
    border: AppColors.sunsetBorder,
    borderStrong: AppColors.sunsetBorderStrong,
    textPrimary: AppColors.sunsetText,
    textSecondary: AppColors.sunsetTextSecondary,
    textMuted: AppColors.sunsetTextMuted,
    primary: AppColors.sunsetPrimary,
    primaryBright: AppColors.sunsetPrimaryBright,
    primaryDeep: AppColors.sunsetPrimaryDeep,
    onPrimary: AppColors.white,
    primaryText: AppColors.sunsetPrimaryDeep,
    accent: AppColors.laser,
    accentText: AppColors.laserDeep,
    success: AppColors.successDeep,
    onSuccess: AppColors.white,
    warning: AppColors.warningDeep,
    onWarning: AppColors.white,
    danger: AppColors.dangerDeep,
    onDanger: AppColors.white,
    info: AppColors.infoDeep,
    onInfo: AppColors.white,
    violetText: AppColors.violetPrimary,
    toolLaser: AppColors.toolLaserDeep,
    toolPen: AppColors.toolPenDeep,
    toolHighlighter: AppColors.toolHighlighterDeep,
    glass: AppColors.paperGlass,
    glassBorder: AppColors.paperGlassBorder,
    shadow: AppColors.paperShadow,
    scrim: AppColors.paperScrim,
  );


  /// The gradient of primary buttons and the brand tile.
  LinearGradient get primaryGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [primaryBright, primary],
      );

  /// The gradient of the green Start buttons, with [onSuccess] on it.
  LinearGradient get successGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark ? const [AppColors.successShade, AppColors.success] : const [AppColors.successDeep, AppColors.successShade],
      );

  @override
  AppPalette copyWith() => this;

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppPalette(
      isDark: t < 0.5 ? isDark : other.isDark,
      background: c(background, other.background),
      surface: c(surface, other.surface),
      surfaceRaised: c(surfaceRaised, other.surfaceRaised),
      surfaceSunken: c(surfaceSunken, other.surfaceSunken),
      border: c(border, other.border),
      borderStrong: c(borderStrong, other.borderStrong),
      textPrimary: c(textPrimary, other.textPrimary),
      textSecondary: c(textSecondary, other.textSecondary),
      textMuted: c(textMuted, other.textMuted),
      primary: c(primary, other.primary),
      primaryBright: c(primaryBright, other.primaryBright),
      primaryDeep: c(primaryDeep, other.primaryDeep),
      onPrimary: c(onPrimary, other.onPrimary),
      primaryText: c(primaryText, other.primaryText),
      accent: c(accent, other.accent),
      accentText: c(accentText, other.accentText),
      success: c(success, other.success),
      onSuccess: c(onSuccess, other.onSuccess),
      warning: c(warning, other.warning),
      onWarning: c(onWarning, other.onWarning),
      danger: c(danger, other.danger),
      onDanger: c(onDanger, other.onDanger),
      info: c(info, other.info),
      onInfo: c(onInfo, other.onInfo),
      violetText: c(violetText, other.violetText),
      toolLaser: c(toolLaser, other.toolLaser),
      toolPen: c(toolPen, other.toolPen),
      toolHighlighter: c(toolHighlighter, other.toolHighlighter),
      glass: c(glass, other.glass),
      glassBorder: c(glassBorder, other.glassBorder),
      shadow: c(shadow, other.shadow),
      scrim: c(scrim, other.scrim),
    );
  }
}

/// Ink or white, whichever reads better on [fill] (the higher WCAG contrast;
/// the two cross at a relative luminance of about 0.19).
Color readableOn(Color fill) => fill.computeLuminance() > 0.19 ? AppColors.ink : AppColors.white;

/// The intent of a button, alert or badge; resolved to colors per theme.
enum AppTone { primary, accent, success, warning, danger, info, neutral }

extension AppToneColors on AppPalette {
  /// The tone as a fill, an icon or text.
  Color tone(AppTone tone) => switch (tone) {
        AppTone.primary => primaryText,
        AppTone.accent => accentText,
        AppTone.success => success,
        AppTone.warning => warning,
        AppTone.danger => danger,
        AppTone.info => info,
        AppTone.neutral => textSecondary,
      };

  /// The solid fill of a button in this tone and the color on it.
  (Color fill, Color on) solid(AppTone tone) => switch (tone) {
        AppTone.primary => (primary, onPrimary),
        AppTone.accent => (accent, AppColors.ink),
        AppTone.success => (success, onSuccess),
        AppTone.warning => (warning, onWarning),
        AppTone.danger => (danger, onDanger),
        AppTone.info => (info, onInfo),
        AppTone.neutral => (textPrimary, background),
      };
}

extension AppPaletteContext on BuildContext {
  /// The palette of the current theme. Outside the app's theme (in tests that
  /// use a bare MaterialApp) the brand palette of the same brightness.
  AppPalette get palette {
    final theme = Theme.of(this);
    return theme.extension<AppPalette>() ??
        (theme.brightness == Brightness.dark ? AppPalette.dark : AppPalette.light);
  }
}
