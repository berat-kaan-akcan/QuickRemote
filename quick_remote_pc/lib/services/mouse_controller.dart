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
    return WindowsMouseController();
  }

  void init();
  
  int get screenWidth;
  int get screenHeight;
  double get currentX;
  double get currentY;

  void moveDelta(double dx, double dy);
  void moveTo(double x, double y);
  void resetToCenter();
}
