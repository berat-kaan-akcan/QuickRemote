import 'dart:async';
import 'dart:io';

import 'powershell_runner.dart';
import 'input/input_service.dart';
import 'input/windows/windows_input_service.dart';
import 'input/linux/linux_input_service.dart';

/// Facade for backwards compatibility with existing InputSimulator references
class InputSimulator {
  static final InputService _instance = _init();

  static InputService _init() {
    if (Platform.isWindows) {
      return WindowsInputService();
    } else if (Platform.isLinux) {
      return LinuxInputService();
    }
    // Fallback or handle other OSs
    return WindowsInputService();
  }

  static set onCommandError(void Function(String detail)? callback) {
    _instance.onCommandError = callback;
  }
  
  static void Function(String detail)? get onCommandError => _instance.onCommandError;

  // Keyboard
  static void pressKey(int vkCode) => _instance.pressKey(vkCode);
  static void pressKeyCombo(List<int> vkCodes) => _instance.pressKeyCombo(vkCodes);
  
  // Mouse
  static void leftClick() => _instance.leftClick();
  static void rightClick() => _instance.rightClick();
  static void leftDown() => _instance.leftDown();
  static void leftUp() => _instance.leftUp();

  // Volume
  static String getAudioControlPSScript() => _instance.getAudioControlPSScript();
  static void volumeUp() => _instance.volumeUp();
  static void volumeDown() => _instance.volumeDown();
  static void volumeMute() => _instance.volumeMute();
  static Future<void> setVolume(int level) => _instance.setVolume(level);

  // PPT
  static void slideNext() => _instance.slideNext();
  static void slidePrev() => _instance.slidePrev();
  static Future<void> slideStart() => _instance.slideStart();
  static Future<void> slideStartAt(int slideNumber) => _instance.slideStartAt(slideNumber);
  static Future<void> slideEnd() => _instance.slideEnd();
  static void blackScreen() => _instance.blackScreen();
  static void whiteScreen() => _instance.whiteScreen();
  static void eraseAllInk() => _instance.eraseAllInk();
  static void toggleLaserCursor() => _instance.toggleLaserCursor();
  static Future<void> setPenColor(int bgrColor) => _instance.setPenColor(bgrColor);
  static Future<void> pptMediaPlayPause() => _instance.pptMediaPlayPause();
  static Future<void> pptMediaRewind() => _instance.pptMediaRewind();

  // SMTC & State
  static Future<Map<String, dynamic>?> getSmtcState() => _instance.getSmtcState();
  static Future<Map<String, dynamic>?> getSlideState() => _instance.getSlideState();
  
  // Dispatcher & PowerShell
  static void executeCommand(String command) => _instance.executeCommand(command);
  
  // PowerShell is still windows specific but we keep it here for existing code
  static Future<String> runPowerShellScript(String script, {bool isPolling = false}) => PowerShellRunner.execute(script, isPolling: isPolling);
  
  // Others
  static void lockPC() => _instance.lockPC();
  static void sysMediaPlayPause() => _instance.sysMediaPlayPause();
  static void sysMediaNext() => _instance.sysMediaNext();
  static void sysMediaPrev() => _instance.sysMediaPrev();
  static void sysMediaStop() => _instance.sysMediaStop();
}
