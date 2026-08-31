import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  // Early Warning Haptic Feedback
  bool _earlyWarningHaptic = true;

  bool get earlyWarningHaptic => _earlyWarningHaptic;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _earlyWarningHaptic = prefs.getBool('early_warning_haptic') ?? true;
    notifyListeners();
  }

  Future<void> setEarlyWarningHaptic(bool value) async {
    _earlyWarningHaptic = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('early_warning_haptic', value);
  }
}
