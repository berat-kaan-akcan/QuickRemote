import 'dart:io';

import 'input/windows/windows_mouse_controller.dart';
import 'input/linux/linux_mouse_controller.dart';

abstract class MouseController {
  factory MouseController() {
    if (Platform.isWindows) {
      return WindowsMouseController();
    } else if (Platform.isLinux) {
      return LinuxMouseController();
    }
    throw UnsupportedError('QuickRemote PC does not support ${Platform.operatingSystem}');
  }

  void init();
  
  int get screenWidth;
  int get screenHeight;
  double get currentX;
  double get currentY;

  void moveDelta(double dx, double dy);

  /// Updates the tracked position without moving the OS cursor
  /// (used when the presenter draws the laser pointer itself).
  void trackDelta(double dx, double dy);
  void moveTo(double x, double y);
  void resetToCenter();
}
