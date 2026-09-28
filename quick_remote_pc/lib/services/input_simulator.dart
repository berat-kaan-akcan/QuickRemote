import 'dart:io';

import 'input/command_router.dart';
import 'input/input_service.dart';
import 'input/windows/windows_input_service.dart';
import 'input/linux/linux_input_service.dart';

/// Static facade over the platform [InputService].
class InputSimulator {
  static final InputService _instance = _init();

  static InputService _init() {
    if (Platform.isWindows) {
      return WindowsInputService();
    } else if (Platform.isLinux) {
      return LinuxInputService();
    }
    throw UnsupportedError('QuickRemote PC does not support ${Platform.operatingSystem}');
  }

  static set onCommandError(void Function(String detail)? callback) {
    _instance.onCommandError = callback;
  }

  static void Function(String detail)? get onCommandError => _instance.onCommandError;

  static String get presenter => _instance.presenter;

  // Dispatcher
  static void executeCommand(String command) => CommandRouter.execute(_instance, command);

  // Laser
  static bool get handlesLaserPointer => _instance.handlesLaserPointer;
  static void laserPointerMoved(double relX, double relY) => _instance.laserPointerMoved(relX, relY);

  // States
  static Future<Map<String, dynamic>?> getSmtcState() => _instance.getSmtcState();
  static Future<Map<String, dynamic>?> getSlideState() => _instance.getSlideState();
  static Future<VolumeState?> getVolumeState() => _instance.getVolumeState();
}
