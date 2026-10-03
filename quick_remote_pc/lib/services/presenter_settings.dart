import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// PC-side presentation preferences, read by the platform input services.
class PresenterSettings {
  PresenterSettings._();

  static const _keepInkKey = 'keep_ink_on_slide_change';

  /// Keep the ink on its slide on NEXT, PREV and jumps, so it shows again
  /// when the show comes back (what PowerPoint and Impress do by
  /// themselves). Off, the ink is erased before the show moves.
  static bool keepInkOnSlideChange = false;

  static bool get clearInkOnSlideChange => !keepInkOnSlideChange;

  static Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      keepInkOnSlideChange = prefs.getBool(_keepInkKey) ?? false;
    } catch (e) {
      debugPrint('PresenterSettings: not loaded: $e');
    }
  }

  static Future<void> setKeepInkOnSlideChange(bool value) async {
    keepInkOnSlideChange = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keepInkKey, value);
  }
}
