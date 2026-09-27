import 'package:win32/win32.dart';
import '../input_service.dart';
import 'command_dispatcher.dart';
import 'keyboard_simulator.dart';
import 'mouse_simulator.dart';
import 'ppt_controller.dart';
import 'slide_state_controller.dart';
import 'smtc_controller.dart';
import 'volume_controller.dart';

class WindowsInputService implements InputService {
  @override
  void Function(String detail)? onCommandError;

  @override
  void executeCommand(String command) {
    CommandDispatcher.executeCommand(command);
  }

  @override
  Future<Map<String, dynamic>?> getSmtcState() => SmtcController.getSmtcState();

  @override
  Future<Map<String, dynamic>?> getSlideState() => SlideStateController.getSlideState();

  @override
  String getAudioControlPSScript() => VolumeController.getAudioControlPSScript();
  @override
  void volumeUp() => VolumeController.volumeUp();
  @override
  void volumeDown() => VolumeController.volumeDown();
  @override
  void volumeMute() => VolumeController.volumeMute();
  @override
  Future<void> setVolume(int level) => VolumeController.setVolume(level);

  @override
  void slideNext() => PptController.slideNext();
  @override
  void slidePrev() => PptController.slidePrev();
  @override
  Future<void> slideStart() => PptController.slideStart();
  @override
  Future<void> slideStartAt(int slideNumber) => PptController.slideStartAt(slideNumber);
  @override
  Future<void> slideEnd() => PptController.slideEnd();
  @override
  void blackScreen() => PptController.blackScreen();
  @override
  void whiteScreen() => PptController.whiteScreen();
  @override
  void eraseAllInk() => PptController.eraseAllInk();
  @override
  void toggleLaserCursor() => PptController.toggleLaserCursor();
  @override
  Future<void> setPenColor(int bgrColor) => PptController.setPenColor(bgrColor);
  @override
  Future<void> pptMediaPlayPause() => PptController.pptMediaPlayPause();
  @override
  Future<void> pptMediaRewind() => PptController.pptMediaRewind();

  @override
  void leftClick() => MouseSimulator.leftClick();
  @override
  void rightClick() => MouseSimulator.rightClick();
  @override
  void leftDown() => MouseSimulator.leftDown();
  @override
  void leftUp() => MouseSimulator.leftUp();

  @override
  void pressKey(int vkCode) => KeyboardSimulator.pressKey(vkCode);
  @override
  void pressKeyCombo(List<int> vkCodes) => KeyboardSimulator.pressKeyCombo(vkCodes);

  @override
  void lockPC() => LockWorkStation();
  
  @override
  void sysMediaPlayPause() => KeyboardSimulator.pressKey(0xB3);
  @override
  void sysMediaNext() => KeyboardSimulator.pressKey(0xB0);
  @override
  void sysMediaPrev() => KeyboardSimulator.pressKey(0xB1);
  @override
  void sysMediaStop() => KeyboardSimulator.pressKey(0xB2);
}
