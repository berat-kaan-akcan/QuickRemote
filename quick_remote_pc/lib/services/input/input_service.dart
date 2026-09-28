typedef VolumeState = ({int volume, bool muted});

abstract class InputService {
  void Function(String detail)? onCommandError;

  /// Presentation program controlled on this platform ('powerpoint' / 'impress').
  /// Sent to the mobile client so it can adapt its texts and controls.
  String get presenter;

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

  // Mouse & Keyboard
  void leftClick();
  void rightClick();
  void leftDown();
  void leftUp();
  void pressKey(int vkCode);
  void pressKeyCombo(List<int> vkCodes);

  // System
  void lockPC();
  void sysMediaPlayPause();
  void sysMediaNext();
  void sysMediaPrev();
  void sysMediaStop();
}
