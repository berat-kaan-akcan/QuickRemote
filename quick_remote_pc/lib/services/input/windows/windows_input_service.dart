import 'package:win32/win32.dart';
import '../input_service.dart';
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
  String get presenter => 'powerpoint';

  @override
  Future<Map<String, dynamic>?> getSmtcState() => SmtcController.getSmtcState();

  @override
  Future<Map<String, dynamic>?> getSlideState() => SlideStateController.getSlideState();

  @override
  Future<VolumeState?> getVolumeState() => VolumeController.getVolumeState();
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
  Future<void> setPenColor(int bgrColor) => PptController.setPenColor(bgrColor);
  @override
  Future<void> pptMediaPlayPause() => PptController.pptMediaPlayPause();
  @override
  Future<void> pptMediaRewind() => PptController.pptMediaRewind();

  @override
  void toggleLaserCursor() => PptController.toggleLaserCursor();
  @override
  void modeArrow() => _switchMode(0x41, laser: false); // Ctrl + A
  @override
  void modeLaser() => _switchMode(0x4C, laser: true); // Ctrl + L
  @override
  void modePen() => _switchMode(0x50, laser: false); // Ctrl + P
  @override
  void modeHighlighter() => _switchMode(0x49, laser: false); // Ctrl + I
  @override
  void modeEraser() => _switchMode(0x45, laser: false); // Ctrl + E
  @override
  void laserOff() => _switchMode(0x41, laser: false); // Ctrl + A

  Future<void> _switchMode(int key, {required bool laser}) async {
    if (await PptController.pressInSlideShow([VK_CONTROL, key])) {
      PptController.setLaserActive(laser);
    }
  }

  // PowerPoint's own laser follows the OS cursor.
  @override
  bool get handlesLaserPointer => false;
  @override
  void laserPointerMoved(double relX, double relY) {}

  @override
  void leftClick() => MouseSimulator.leftClick();
  @override
  void rightClick() => MouseSimulator.rightClick();
  @override
  void leftDown() => MouseSimulator.leftDown();
  @override
  void leftUp() => MouseSimulator.leftUp();

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
