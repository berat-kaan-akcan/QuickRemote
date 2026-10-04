import 'package:flutter/painting.dart';

/// Colors shared by the phone and PC apps. The PC app has a copy of the
/// first seven and of [caution]; keep them identical.
abstract final class AppColors {
  static const background = Color(0xFF0F172A);
  static const surface = Color(0xFF1E293B);
  static const primary = Color(0xFF005B96);
  static const accent = Color(0xFF00BCD4);
  static const success = Color(0xFF4CAF50);
  static const warning = Color(0xFFFF9800);
  static const danger = Color(0xFFFF5252);

  // Drawing tools (the eraser uses [warning])
  static const laser = Color(0xFFFF1744);
  static const pen = Color(0xFF00E676);
  static const highlighter = Color(0xFFFFEA00);

  // Bluetooth mode
  static const bluetooth = Color(0xFF1565C0);
  static const bluetoothLight = Color(0xFF64B5F6);
  static const bluetoothDark = Color(0xFF006064);

  // Accents
  static const caution = Color(0xFFFFB74D); // softer than [warning]
  static const info = Color(0xFF64FFDA);
  static const blue = Color(0xFF2979FF);
  static const slideInfo = Color(0xFF1A1F38);

  // Ink swatches in the color picker
  static const inkRed = Color(0xFFFF1744);
  static const inkBlue = blue;
  static const inkGreen = Color(0xFF00E676);
  static const inkYellow = Color(0xFFFFEA00);
  static const inkWhite = Color(0xFFFFFFFF);
  static const inkPurple = Color(0xFFD500F9);

  // Media cards
  static const mediaRose = Color(0xFFF43F5E);
  static const mediaPink = Color(0xFFEC4899);
  static const mediaViolet = Color(0xFF8B5CF6);
  static const mediaSky = Color(0xFF0EA5E9);
  static const mediaSkyLight = Color(0xFF38BDF8);
  static const mediaEmerald = Color(0xFF10B981);
  static const mediaEmeraldLight = Color(0xFF34D399);

  // Analytics
  static const analyticsIndigo = Color(0xFF6C63FF);
  static const analyticsIndigoDark = Color(0xFF5A54E0);
  static const analyticsTeal = Color(0xFF4ECDC4);
  static const analyticsTealDark = Color(0xFF3DBDB5);
  static const analyticsCoral = Color(0xFFFF6B6B);
  static const analyticsCoralDark = Color(0xFFE05555);
}
