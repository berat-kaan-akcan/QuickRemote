import 'dart:io';

import 'package:flutter/foundation.dart';

import 'input/command_router.dart';
import 'input/input_service.dart';
import 'input/windows/windows_input_service.dart';
import 'input/linux/linux_input_service.dart';
import 'input/overlay_input_service.dart';
import 'overlay/linux_laser_overlay.dart';
import 'overlay/windows_laser_overlay.dart';

/// Static facade over the platform [InputService].
class InputSimulator {
  static InputService _instance = _init();

  /// Replaces the platform service; set it before anything else touches
  /// [InputSimulator] so the real one is never created.
  @visibleForTesting
  static set instance(InputService service) => _instance = service;

  static InputService _init() {
    if (Platform.isWindows) {
      return OverlayInputService(WindowsInputService(), WindowsLaserOverlay.instance);
    } else if (Platform.isLinux) {
      return OverlayInputService(LinuxInputService(), LinuxLaserOverlay.instance);
    }
    throw UnsupportedError('QuickRemote PC does not support ${Platform.operatingSystem}');
  }

  static set onCommandError(CommandErrorHandler? callback) {
    _instance.onCommandError = callback;
  }

  static CommandErrorHandler? get onCommandError => _instance.onCommandError;

  static String get presenter => _instance.presenter;
  static List<String> get presenters => _instance.presenters;

  // Dispatcher
  /// [keepInk]: the sending phone's SET_KEEP_INK, for the slide commands.
  static void executeCommand(String command, {bool keepInk = false}) =>
      CommandRouter.execute(_instance, command, keepInk: keepInk);

  // Laser
  /// The laser works outside a slideshow too (QuickRemote's overlay draws it).
  static bool get toolsAnywhere {
    final service = _instance;
    return service is OverlayInputService && service.toolsAnywhere;
  }

  /// The overlay has a magnifier (MODE_ZOOM; Windows).
  static bool get zoomAvailable {
    final service = _instance;
    return service is OverlayInputService && service.zoomAvailable;
  }

  static bool get handlesLaserPointer => _instance.handlesLaserPointer;
  static void laserPointerMoved(double relX, double relY) => _instance.laserPointerMoved(relX, relY);
  static bool get handlesDrawPointer => _instance.handlesDrawPointer;
  static void drawPointerMoved(double relX, double relY) => _instance.drawPointerMoved(relX, relY);

  // States
  static Future<Map<String, dynamic>?> getSmtcState() => _instance.getSmtcState();
  static Future<Map<String, dynamic>?> getSlideState() => _instance.getSlideState();
  static Future<VolumeState?> getVolumeState() => _instance.getVolumeState();
  static Future<PresenterCaps> capabilities() => _instance.capabilities();
  static Future<SlideImage?> exportSlide(int index, int width) => _instance.exportSlide(index, width);
  static Future<ScreenCapture?> captureScreen() => _instance.captureScreen();
}
