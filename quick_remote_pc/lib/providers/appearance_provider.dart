import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The PC's light/dark mode (Settings → Appearance); the system's by default.
class AppearanceProvider extends ChangeNotifier {
  static const _key = 'theme_mode';

  ThemeMode _mode = ThemeMode.system;

  /// Picked before the stored mode was read; the late read must not undo it.
  bool _picked = false;

  ThemeMode get mode => _mode;

  AppearanceProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(_key);
    if (_picked) return;
    _mode = ThemeMode.values.firstWhere((m) => m.name == name, orElse: () => ThemeMode.system);
    notifyListeners();
  }

  Future<void> setMode(ThemeMode mode) async {
    _picked = true;
    _mode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    if (mode == ThemeMode.system) {
      await prefs.remove(_key);
    } else {
      await prefs.setString(_key, mode.name);
    }
  }
}
