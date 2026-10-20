import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/overlay/laser_overlay.dart';

/// Who draws the laser (Settings → Laser): QuickRemote's overlay or the
/// program. Kept in [LaserOverlaySettings] for the input service.
class LaserOverlayProvider extends ChangeNotifier {
  static const _key = 'laser_overlay';

  /// Picked before the stored mode was read; the late read must not undo it.
  bool _picked = false;

  LaserOverlayMode get mode => LaserOverlaySettings.mode;

  LaserOverlayProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(_key);
    if (_picked) return;
    LaserOverlaySettings.mode = LaserOverlayMode.fromName(name);
    notifyListeners();
  }

  Future<void> setMode(LaserOverlayMode mode) async {
    _picked = true;
    LaserOverlaySettings.mode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    if (mode == LaserOverlayMode.auto) {
      await prefs.remove(_key);
    } else {
      await prefs.setString(_key, mode.name);
    }
  }
}
