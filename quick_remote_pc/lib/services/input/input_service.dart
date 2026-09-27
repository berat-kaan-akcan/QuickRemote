abstract class InputService {
  void Function(String detail)? onCommandError;

  // Dispatcher
  void executeCommand(String command);

  // States
  Future<Map<String, dynamic>?> getSmtcState();
  Future<Map<String, dynamic>?> getSlideState();

  // Volume (for input simulator facade)
  String getAudioControlPSScript();
  void volumeUp();
  void volumeDown();
  void volumeMute();
  Future<void> setVolume(int level);

  // PPT (for direct usage)
  void slideNext();
  void slidePrev();
  Future<void> slideStart();
  Future<void> slideStartAt(int slideNumber);
  Future<void> slideEnd();
  void blackScreen();
  void whiteScreen();
  void eraseAllInk();
  void toggleLaserCursor();
  Future<void> setPenColor(int bgrColor);
  Future<void> pptMediaPlayPause();
  Future<void> pptMediaRewind();

  // Mouse & Keyboard (Others)
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
