import 'package:quick_remote_shared/quick_remote_shared.dart';

export 'package:quick_remote_shared/quick_remote_shared.dart' show RemoteError;

typedef VolumeState = ({int volume, bool muted});

/// Reports a failed command to the phones; [info] is untranslated detail.
typedef CommandErrorHandler = void Function(RemoteError error, [String? info]);

abstract class InputService {
  CommandErrorHandler? onCommandError;

  /// Main presentation program of this platform ('powerpoint' / 'impress').
  /// Sent to the mobile client so it can adapt its texts and controls.
  String get presenter;

  /// Every presentation program this platform controls, [presenter] first
  /// ('wps' on both platforms). SLIDE_STATE names the one running the show.
  List<String> get presenters;

  // States
  Future<Map<String, dynamic>?> getSmtcState();
  Future<Map<String, dynamic>?> getSlideState();
  Future<VolumeState?> getVolumeState();

  // Volume
  void volumeUp();
  void volumeDown();
  void volumeMute();
  Future<void> setVolume(int level);

  // Presentation
  void slideNext();
  void slidePrev();
  Future<void> slideStart();
  Future<void> slideStartAt(int slideNumber);
  Future<void> slideEnd();
  void blackScreen();
  void whiteScreen();
  void eraseAllInk();
  Future<void> setPenColor(int bgrColor);
  Future<void> setHighlighterColor(int bgrColor);
  Future<void> pptMediaPlayPause();
  Future<void> pptMediaRewind();

  // Drawing / pointer modes
  void toggleLaserCursor();
  void modeArrow();
  void modeLaser();
  void modePen();
  void modeHighlighter();
  void modeEraser();
  void laserOff();

  /// True when the service renders the laser pointer itself; the server then
  /// feeds [laserPointerMoved] instead of moving the OS cursor.
  bool get handlesLaserPointer;

  /// Laser position relative to the screen (0..1 on both axes).
  void laserPointerMoved(double relX, double relY);

  /// True while the service draws the touch gesture itself (Impress's
  /// highlighter strokes); the server then feeds TOUCH motion, and the
  /// position before LEFT_DOWN, to [drawPointerMoved] instead of moving the
  /// OS cursor.
  bool get handlesDrawPointer;

  /// Drawing position relative to the screen (0..1 on both axes).
  void drawPointerMoved(double relX, double relY);

  // Mouse & Keyboard
  void leftClick();
  void rightClick();
  void leftDown();
  void leftUp();

  // System
  void lockPC();
  void sysMediaPlayPause();
  void sysMediaNext();
  void sysMediaPrev();
  void sysMediaStop();
}
