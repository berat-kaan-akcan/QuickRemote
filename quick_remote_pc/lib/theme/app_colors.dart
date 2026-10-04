import 'package:flutter/painting.dart';

/// Colors shared by the phone and PC apps: the first seven and [caution];
/// keep them identical to the phone app's copy. The rest are the PC's own.
abstract final class AppColors {
  static const background = Color(0xFF0F172A);
  static const surface = Color(0xFF1E293B);
  static const primary = Color(0xFF005B96);
  static const accent = Color(0xFF00BCD4);
  static const success = Color(0xFF4CAF50);
  static const warning = Color(0xFFFF9800);
  static const danger = Color(0xFFFF5252);

  static const caution = Color(0xFFFFB74D); // softer than [warning]
  static const muted = Color(0xFF90A4AE);
  static const stop = Color(0xFFFF1744);
  static const alert = Color(0xFFF44336);
}
