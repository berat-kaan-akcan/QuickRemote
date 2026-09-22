import 'package:flutter/material.dart';

/// Tüm popup'lar (Dialog ve BottomSheet) için ortak tema sabitleri.
class AppPopupTheme {
  AppPopupTheme._();

  // ── Arkaplan Renkleri ──
  static const Color dialogBg = Color(0xFF1E293B);
  static const Color bottomSheetBg = Color(0xFF1E293B);
  static const double bottomSheetBgAlpha = 0.85;
  static const Color fullScreenBg = Color(0xFF0D0D1A);

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
  static const Color hintTextColor = Color(0x66FFFFFF); // white.α0.4

  // ── Aksiyon Buton Renkleri (amaca göre) ──
  static const Color dangerColor = Color(0xFFFF5252);
  static const Color warningColor = Color(0xFFFF9800);
  static const Color successColor = Color(0xFF4CAF50);
  static const Color infoColor = Color(0xFF64FFDA);

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
      hintStyle: const TextStyle(color: hintTextColor),
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
