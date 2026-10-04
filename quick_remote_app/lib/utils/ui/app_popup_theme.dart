import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// Tüm popup'lar (Dialog ve BottomSheet) için ortak tema sabitleri.
class AppPopupTheme {
  AppPopupTheme._();

  // ── Arkaplan Renkleri ──
  static const Color dialogBg = AppColors.surface;
  static const Color bottomSheetBg = AppColors.surface;
  static const double bottomSheetBgAlpha = 0.85;
  static const Color fullScreenBg = AppColors.background;

  // ── Köşe Yuvarlama ──
  static const double dialogRadius = 24.0;
  static const double bottomSheetRadius = 32.0;
  static const double buttonRadius = 12.0;
  static const double inputRadius = 12.0;

  // ── Handle Bar ──
  static const double handleWidth = 48.0;
  static const double handleHeight = 5.0;
  static const double handleRadius = 10.0;
  static const Color handleColor = Colors.white30;

  // ── Blur ──
  static const double blurSigma = 20.0;

  // ── Kenarlık ──
  static const double borderAlpha = 0.2;

  // ── Metin Renkleri ──
  static const Color titleColor = Colors.white;
  static const Color cancelTextColor = Colors.white70;
  static final Color hintTextColor = Colors.white.withValues(alpha: 0.4);

  // ── Aksiyon Buton Renkleri (amaca göre) ──
  static const Color dangerColor = AppColors.danger;
  static const Color warningColor = AppColors.warning;
  static const Color successColor = AppColors.success;
  static const Color infoColor = AppColors.info;

  // ── Input Field ──
  static InputDecoration inputDecoration({
    required BuildContext context,
    String? hintText,
    String? labelText,
    String? helperText,
    Widget? prefixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      labelText: labelText,
      helperText: helperText,
      hintStyle: TextStyle(color: hintTextColor),
      labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
      helperStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
      prefixIcon: prefixIcon,
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.05),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(inputRadius),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
        ),
        borderRadius: BorderRadius.circular(inputRadius),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.primary,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(inputRadius),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}
