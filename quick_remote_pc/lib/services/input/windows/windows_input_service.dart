import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';
import '../input_service.dart';
import 'keyboard_simulator.dart';
import 'mouse_simulator.dart';
import 'ppt_controller.dart';
import 'presenter_com.dart';
import 'slide_exporter.dart';
import 'slide_state_controller.dart';
import 'smtc_controller.dart';
import 'volume_controller.dart';
import 'window_capture.dart';

class WindowsInputService implements InputService {
  @override
  CommandErrorHandler? onCommandError;

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
  Future<SlideImage?> exportSlide(int index, int width) => SlideExporter.export(index, width);

  /// The show's window ([PresenterCom.active]'s), else the foreground
  /// window when it is a PDF viewer or browser covering its monitor, taken
  /// with PrintWindow. Not tried on Windows yet.
  @override
  Future<ScreenCapture?> captureScreen() async {
    final active = PresenterCom.active;
    if (active != null) {
      final show = PptController.showWindow(active);
      return show == null ? null : WindowCapture.capture(show);
    }
    if (!FrontWindow.isViewer(PptController.frontWindow())) return null;
    final front = GetForegroundWindow();
    if (front.isNull || !WindowCapture.coversMonitor(front)) return null;
    return WindowCapture.capture(front);
  }

  /// The show the last slide state found ([PresenterCom.active]) and the
  /// foreground window, read with a few Win32 calls (no PowerShell), so it
  /// is cheap enough to poll. Both programs do everything but WPS's media
  /// rewind and its slide pictures (COM `Player` and `Export` are not
  /// verified there); their editors start a show at a slide (COM GotoSlide).
  @override
  Future<PresenterCaps> capabilities() async {
    final front = PptController.frontWindow();
    final caps = switch (PresenterCom.active) {
      'powerpoint' => {..._showCaps, RemoteCaps.rewind, RemoteCaps.previews},
      'wps' => _showCaps,
      _ => front == FrontWindow.editor ? const {RemoteCaps.goto} : const <String>{},
    };
    return PresenterCaps(front: front, caps: caps);
  }

  static const _showCaps = {
    RemoteCaps.laser,
    RemoteCaps.pen,
    RemoteCaps.highlighter,
    RemoteCaps.eraser,
    RemoteCaps.eraseAll,
    RemoteCaps.blank,
    RemoteCaps.media,
    RemoteCaps.goto,
    RemoteCaps.notes,
    RemoteCaps.colors,
  };

  /// The focused window (a browser or PDF viewer in full screen): the
  /// overlay goes to its monitor. PowerPoint and WPS keep their own laser
  /// unless the PC's Laser setting says always; then their show is in front.
  @override
  Future<ScreenArea?> laserArea() async {
    final window = GetForegroundWindow();
    if (window.isNull) return null;
    final rect = calloc<RECT>();
    try {
      if (!GetWindowRect(window, rect).value) return null;
      final r = rect.ref;
      return (x: r.left, y: r.top, width: r.right - r.left, height: r.bottom - r.top);
    } finally {
      calloc.free(rect);
    }
  }
  @override
  void volumeUp() => VolumeController.volumeUp();
  @override
  void volumeDown() => VolumeController.volumeDown();
  @override
  void volumeMute() => VolumeController.volumeMute();
  @override
  Future<void> setVolume(int level) => VolumeController.setVolume(level);

  @override
  void slideNext({bool keepInk = false}) => PptController.slideNext(keepInk: keepInk);
  @override
  void slidePrev({bool keepInk = false}) => PptController.slidePrev(keepInk: keepInk);
  // A show that starts has no ink yet; START_AT in a running show jumps
  // through COM, which leaves the ink to the program as before.
  @override
  Future<void> slideStart({bool keepInk = false}) => PptController.slideStart();
  @override
  Future<void> slideStartAt(int slideNumber, {bool keepInk = false}) => PptController.slideStartAt(slideNumber);
  @override
  Future<void> slideEnd() => PptController.slideEnd();
  @override
  void blackScreen() => PptController.blackScreen();
  @override
  void whiteScreen() => PptController.whiteScreen();
  @override
  void eraseAllInk() => PptController.eraseAllInk();
  // Only the overlay has a spotlight and strokes to take back.
  @override
  void modeSpotlight() => onCommandError?.call(RemoteError.commandFailed, 'NO_SPOTLIGHT');
  @override
  void modeZoom() => onCommandError?.call(RemoteError.commandFailed, 'NO_ZOOM');
  @override
  void undoInk() {}
  @override
  void phonesGone() {}
  // COM reaches every WPS on Windows: there is nothing to take over.
  @override
  Future<RemoteError?> takeOverWps() async => RemoteError.wpsTakeOverNoWps;
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
  // instead (its Ctrl+L and Ctrl+E do something else), its laser pen Ctrl+R
  // (PptController.wpsLaser). Its highlighter has only Ctrl+I.
  @override
  void modeArrow() => _switchMode(0x41, laser: false, wpsPointer: PptController.pointerAutoArrow); // Ctrl + A
  @override
  void modeLaser() => _switchMode(0x4C, laser: true); // Ctrl + L
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
    final bool switched;
    if (PresenterCom.wpsActive && laser) {
      switched = await PptController.wpsLaser(true);
    } else if (PresenterCom.wpsActive) {
      // The pointer types leave WPS's laser pen on: Ctrl+A puts it away.
      if (PptController.laserActive) await PptController.wpsLaser(false);
      switched = wpsPointer != null
          ? await PptController.setPointerType(wpsPointer)
          : await PptController.pressInSlideShow([VK_CONTROL, key]);
    } else {
      switched = await PptController.pressInSlideShow([VK_CONTROL, key]);
    }
    if (switched) {
      PptController.setLaserActive(laser);
      if (color != null) await PptController.setPointerColor(color);
    }
  }

  // PowerPoint's and WPS's lasers follow the OS cursor.
  @override
  bool get handlesLaserPointer => false;
  @override
  void laserPointerMoved(double relX, double relY) {}
  @override
  bool get handlesDrawPointer => false;
  @override
  void drawPointerMoved(double relX, double relY) {}

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
