import 'package:win32/win32.dart';
import '../input_service.dart';
import 'keyboard_simulator.dart';
import 'mouse_simulator.dart';
import 'ppt_controller.dart';
import 'presenter_com.dart';
import 'slide_state_controller.dart';
import 'smtc_controller.dart';
import 'volume_controller.dart';

class WindowsInputService implements InputService {
  @override
  void Function(String detail)? onCommandError;

  @override
  String get presenter => 'powerpoint';

  @override
  List<String> get presenters => const ['powerpoint', 'wps'];

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
  // PowerPoint's COM API has a single PointerColor, and Ctrl+P / Ctrl+I
  // switch to each tool with the color it had: the chosen colors are applied
  // again after the switch.
  int? _penColor;
  int? _highlighterColor;
  static const _defaultPenColor = 0x0000FF; // red, BGR

  @override
  Future<void> setPenColor(int bgrColor) {
    _penColor = bgrColor;
    return PptController.setPointerColor(bgrColor);
  }

  @override
  Future<void> setHighlighterColor(int bgrColor) async {
    // Applied at the next Ctrl+I; the phone picks colors between gestures.
    _highlighterColor = bgrColor;
  }
  @override
  Future<void> pptMediaPlayPause() => PptController.pptMediaPlayPause();
  @override
  Future<void> pptMediaRewind() => PptController.pptMediaRewind();

  @override
  void toggleLaserCursor() => PptController.toggleLaserCursor();
  // PowerPoint's Ctrl shortcuts. WPS gets the pointer type through COM
  // instead: its Ctrl+L and Ctrl+E do something else, and it has no laser
  // (the visible arrow follows the phone). Its highlighter has only Ctrl+I.
  @override
  void modeArrow() => _switchMode(0x41, laser: false, wpsPointer: PptController.pointerAutoArrow); // Ctrl + A
  @override
  void modeLaser() => _switchMode(0x4C, laser: true, wpsPointer: PptController.pointerArrow); // Ctrl + L
  @override
  void modePen() => _switchMode(0x50,
      laser: false,
      color: _highlighterColor == null ? null : _penColor ?? _defaultPenColor,
      wpsPointer: PptController.pointerPen); // Ctrl + P
  @override
  void modeHighlighter() => _switchMode(0x49, laser: false, color: _highlighterColor); // Ctrl + I
  @override
  void modeEraser() => _switchMode(0x45, laser: false, wpsPointer: PptController.pointerEraser); // Ctrl + E
  @override
  void laserOff() => _switchMode(0x41, laser: false, wpsPointer: PptController.pointerAutoArrow); // Ctrl + A

  Future<void> _switchMode(int key, {required bool laser, int? color, int? wpsPointer}) async {
    final switched = PresenterCom.wpsActive && wpsPointer != null
        ? await PptController.setPointerType(wpsPointer)
        : await PptController.pressInSlideShow([VK_CONTROL, key]);
    if (switched) {
      PptController.setLaserActive(laser);
      if (color != null) await PptController.setPointerColor(color);
    }
  }

  // PowerPoint's own laser, and WPS's arrow, follow the OS cursor.
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
