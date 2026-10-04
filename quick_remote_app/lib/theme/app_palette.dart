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

  final Color toolLaser;
  final Color toolPen;
  final Color toolHighlighter;

  /// Translucent fill and edge of glass panels.
  final Color glass;
  final Color glassBorder;
  final Color shadow;
  final Color scrim;

  /// The eraser tool shares the warning color.
  Color get toolEraser => warning;

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
    toolLaser: AppColors.toolLaser,
    toolPen: AppColors.toolPen,
    toolHighlighter: AppColors.toolHighlighter,
    glass: AppColors.inkGlass,
    glassBorder: AppColors.inkGlassBorder,
    shadow: AppColors.inkShadow,
    scrim: AppColors.inkScrim,
  );

  /// The gradient of primary buttons and the brand tile.
  LinearGradient get primaryGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [primaryBright, primary],
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
