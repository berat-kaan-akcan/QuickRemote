import 'dart:io';

import '../linux/linux_autostart.dart';
import 'windows_autostart.dart';

/// Starting the app when the user logs in (Settings → "Start at login"),
/// with its window hidden (`--minimized`).
abstract class Autostart {
  /// The platform's implementation; null where there is none.
  static final Autostart? instance = Platform.isLinux
      ? LinuxAutostart()
      : Platform.isWindows
      ? WindowsAutostart()
      : null;

  Future<bool> isEnabled();

  /// Turns it on or off; false when that failed.
  Future<bool> setEnabled(bool enabled);

  /// Points an enabled entry at the build running now (it may have moved).
  Future<void> refresh();
}
