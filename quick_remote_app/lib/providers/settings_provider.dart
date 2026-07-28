import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  // Laser Color Preference
  // 0: Red, 1: Green, 2: Blue
  int _laserColorIndex = 0;
  
  // Early Warning Haptic Feedback
  bool _earlyWarningHaptic = true;

  // Clear Ink On Next Slide
  bool _clearInkOnNext = false;

  int get laserColorIndex => _laserColorIndex;
  bool get earlyWarningHaptic => _earlyWarningHaptic;
  bool get clearInkOnNext => _clearInkOnNext;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _laserColorIndex = prefs.getInt('laser_color_index') ?? 0;
    _earlyWarningHaptic = prefs.getBool('early_warning_haptic') ?? true;
    _clearInkOnNext = prefs.getBool('clear_ink_on_next') ?? false;
    notifyListeners();
  }

  Future<void> setLaserColorIndex(int index) async {
    _laserColorIndex = index;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('laser_color_index', index);
  }

  Future<void> setEarlyWarningHaptic(bool value) async {
    _earlyWarningHaptic = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('early_warning_haptic', value);
  }

  Future<void> setClearInkOnNext(bool value) async {
    _clearInkOnNext = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('clear_ink_on_next', value);
  }

  Color get laserColor {
    switch (_laserColorIndex) {
      case 1:
        return const Color(0xFF00E676); // Green
      case 2:
        return const Color(0xFF2979FF); // Blue
      case 0:
      default:
        return const Color(0xFFFF1744); // Red
    }
  }
}
