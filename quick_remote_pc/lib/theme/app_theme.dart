import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_palette.dart';
import 'app_tokens.dart';
import 'app_typography.dart';

/// The light and dark themes. The app follows the system setting.
abstract final class AppTheme {
  static final light = _build(AppPalette.light);
  static final dark = _build(AppPalette.dark);

  /// Status and navigation bar icons that stay readable on [p.background].
  static SystemUiOverlayStyle overlayStyle(AppPalette p) => SystemUiOverlayStyle(
        statusBarColor: AppColors.white.withValues(alpha: 0),
        systemNavigationBarColor: AppColors.white.withValues(alpha: 0),
        systemNavigationBarContrastEnforced: false,
        statusBarIconBrightness: p.isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: p.isDark ? Brightness.dark : Brightness.light,
        systemNavigationBarIconBrightness: p.isDark ? Brightness.light : Brightness.dark,
      );

  static ThemeData _build(AppPalette p) {
    final brightness = p.isDark ? Brightness.dark : Brightness.light;
    final scheme = ColorScheme(
      brightness: brightness,
      primary: p.primaryText,
      onPrimary: p.isDark ? AppColors.ink : AppColors.white,
      primaryContainer: p.primary.withValues(alpha: p.isDark ? 0.28 : 0.12),
      onPrimaryContainer: p.primaryText,
      secondary: p.accent,
      onSecondary: AppColors.ink,
      tertiary: p.info,
      onTertiary: p.onInfo,
      error: p.danger,
      onError: p.onDanger,
      surface: p.surface,
      onSurface: p.textPrimary,
      onSurfaceVariant: p.textSecondary,
      surfaceContainerLowest: p.background,
      surfaceContainerLow: p.surface,
      surfaceContainer: p.surface,
      surfaceContainerHigh: p.surfaceRaised,
      surfaceContainerHighest: p.surfaceSunken,
      outline: p.borderStrong,
      outlineVariant: p.border,
      shadow: p.shadow,
      scrim: p.scrim,
      inverseSurface: p.textPrimary,
      onInverseSurface: p.background,
      inversePrimary: p.primary,
    );
    final text = AppType.textTheme(p.textPrimary, p.textSecondary);
    final buttonShape = RoundedRectangleBorder(borderRadius: AppRadius.all(AppRadius.md));
    const buttonSize = Size(64, 52);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: AppType.text,
      textTheme: text,
      scaffoldBackgroundColor: p.background,
      canvasColor: p.background,
      splashFactory: InkRipple.splashFactory,
      highlightColor: p.textPrimary.withValues(alpha: 0.04),
      splashColor: p.textPrimary.withValues(alpha: 0.06),
      hoverColor: p.textPrimary.withValues(alpha: 0.04),
      focusColor: p.primaryText.withValues(alpha: 0.16),
      dividerColor: p.border,
      iconTheme: IconThemeData(color: p.textSecondary, size: 22),
      extensions: [p],
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: AppPageTransitionsBuilder(),
          TargetPlatform.iOS: AppPageTransitionsBuilder(),
          TargetPlatform.linux: AppPageTransitionsBuilder(),
          TargetPlatform.windows: AppPageTransitionsBuilder(),
          TargetPlatform.macOS: AppPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: p.background.withValues(alpha: 0),
        surfaceTintColor: p.background.withValues(alpha: 0),
        foregroundColor: p.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: AppSpace.xs,
        titleTextStyle: AppType.title.copyWith(color: p.textPrimary, fontSize: 20),
        iconTheme: IconThemeData(color: p.textPrimary),
        systemOverlayStyle: overlayStyle(p),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: p.primary,
          foregroundColor: p.onPrimary,
          disabledBackgroundColor: p.surfaceSunken,
          disabledForegroundColor: p.textMuted,
          minimumSize: buttonSize,
          shape: buttonShape,
          textStyle: AppType.label,
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.xl),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: p.primary,
          foregroundColor: p.onPrimary,
          elevation: 0,
          minimumSize: buttonSize,
          shape: buttonShape,
          textStyle: AppType.label,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: p.textPrimary,
          side: BorderSide(color: p.borderStrong),
          minimumSize: buttonSize,
          shape: buttonShape,
          textStyle: AppType.label,
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.xl),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: p.primaryText,
          minimumSize: const Size(48, 44),
          shape: buttonShape,
          textStyle: AppType.label,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: p.textSecondary,
          minimumSize: const Size(AppSpace.minTouch, AppSpace.minTouch),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.surfaceSunken,
        hintStyle: AppType.body.copyWith(color: p.textMuted),
        labelStyle: AppType.body.copyWith(color: p.textSecondary),
        floatingLabelStyle: AppType.bodySmall.copyWith(color: p.primaryText, fontWeight: FontWeight.w600),
        helperStyle: AppType.bodySmall.copyWith(color: p.textMuted),
        prefixIconColor: p.textMuted,
        suffixStyle: AppType.bodySmall.copyWith(color: p.textMuted),
        counterStyle: AppType.bodySmall.copyWith(color: p.textMuted, fontSize: 11),
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: AppRadius.all(AppRadius.md),
          borderSide: BorderSide(color: p.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.all(AppRadius.md),
          borderSide: BorderSide(color: p.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.all(AppRadius.md),
          borderSide: BorderSide(color: p.primaryText, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.all(AppRadius.md),
          borderSide: BorderSide(color: p.danger),
        ),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: p.primaryText,
        selectionColor: p.primaryText.withValues(alpha: 0.3),
        selectionHandleColor: p.primaryText,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.surfaceRaised,
        surfaceTintColor: p.surfaceRaised.withValues(alpha: 0),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.all(AppRadius.xl),
          side: BorderSide(color: p.border),
        ),
        titleTextStyle: AppType.title.copyWith(color: p.textPrimary),
        contentTextStyle: AppType.body.copyWith(color: p.textSecondary),
        barrierColor: p.scrim,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.surfaceRaised,
        surfaceTintColor: p.surfaceRaised.withValues(alpha: 0),
        modalBackgroundColor: p.surfaceRaised,
        modalBarrierColor: p.scrim,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? AppColors.white : p.textMuted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? p.primary : p.surfaceSunken,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? p.primary : p.borderStrong,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? p.primary : null,
        ),
        checkColor: WidgetStatePropertyAll(p.onPrimary),
        side: BorderSide(color: p.borderStrong, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.all(5)),
      ),
      sliderTheme: SliderThemeData(
        trackHeight: 6,
        activeTrackColor: p.primaryText,
        inactiveTrackColor: p.surfaceSunken,
        thumbColor: AppColors.white,
        overlayColor: p.primaryText.withValues(alpha: 0.16),
        valueIndicatorColor: p.textPrimary,
        valueIndicatorTextStyle: AppType.labelSmall.copyWith(color: p.background),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: p.primaryText,
        linearTrackColor: p.surfaceSunken,
        circularTrackColor: p.surfaceSunken,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          foregroundColor: p.textSecondary,
          selectedForegroundColor: p.onPrimary,
          selectedBackgroundColor: p.primary,
          side: BorderSide(color: p.border),
          textStyle: AppType.labelSmall,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: p.surfaceSunken,
        selectedColor: p.primary.withValues(alpha: 0.16),
        labelStyle: AppType.labelSmall.copyWith(color: p.textPrimary),
        side: BorderSide(color: p.border),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.all(AppRadius.pill)),
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm, vertical: AppSpace.xs),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: p.textSecondary,
        textColor: p.textPrimary,
        titleTextStyle: AppType.titleSmall.copyWith(color: p.textPrimary),
        subtitleTextStyle: AppType.bodySmall.copyWith(color: p.textSecondary),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.all(AppRadius.md)),
      ),
      dividerTheme: DividerThemeData(color: p.border, thickness: 1, space: 1),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: p.textPrimary.withValues(alpha: 0.94),
          borderRadius: AppRadius.all(AppRadius.xs),
        ),
        textStyle: AppType.labelSmall.copyWith(color: p.background),
        waitDuration: const Duration(milliseconds: 400),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: p.surfaceRaised,
        surfaceTintColor: p.surfaceRaised.withValues(alpha: 0),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.all(AppRadius.md),
          side: BorderSide(color: p.border),
        ),
        textStyle: AppType.body.copyWith(color: p.textPrimary),
      ),
    );
  }
}

/// Route transition: the new page fades in while rising 3 % of its height;
/// the page below dims a little. Nothing moves when motion is reduced.
class AppPageTransitionsBuilder extends PageTransitionsBuilder {
  const AppPageTransitionsBuilder();

  @override
  Duration get transitionDuration => AppMotion.page;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (AppMotion.reduced(context)) return child;
    final enter = CurvedAnimation(parent: animation, curve: AppMotion.standard, reverseCurve: AppMotion.exit);
    final below = CurvedAnimation(parent: secondaryAnimation, curve: AppMotion.standard);
    return FadeTransition(
      opacity: Tween<double>(begin: 1, end: 0.6).animate(below),
      child: FadeTransition(
        opacity: enter,
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 0.03), end: Offset.zero).animate(enter),
          child: child,
        ),
      ),
    );
  }
}
