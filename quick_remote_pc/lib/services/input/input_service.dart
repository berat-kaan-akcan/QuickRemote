import 'dart:typed_data';

import 'package:quick_remote_shared/quick_remote_shared.dart';

export 'package:quick_remote_shared/quick_remote_shared.dart' show FrontWindow, PresenterCaps, RemoteCaps, RemoteError;

typedef VolumeState = ({int volume, bool muted});

/// A window's place on the desktop, in X11 root pixels (Linux) or physical
/// pixels (Windows).
typedef ScreenArea = ({int x, int y, int width, int height});

/// A slide exported as a JPEG, [width] × [height] pixels.
typedef SlideImage = ({Uint8List jpeg, int width, int height});

/// A stroke of QuickRemote's overlay to draw on a [ScreenCapture]: points
/// are fractions of the picture, [rgb] is 0xRRGGBB.
typedef CaptureStroke = ({bool highlighter, int rgb, List<(double, double)> points});

/// A window's picture as raw pixels: [width] × [height], 4 bytes a pixel in
/// blue, green, red, unused order (Windows' and X11's 32-bit layout), rows
/// [stride] bytes apart, the top row first. [ink] is drawn on top of it
/// (the overlay's strokes are in a window of their own, not in the picture).
class ScreenCapture {
  ScreenCapture({
    required this.pixels,
    required this.width,
    required this.height,
    int? stride,
    this.ink = const [],
  }) : stride = stride ?? width * 4;

  final Uint8List pixels;
  final int width;
  final int height;
  final int stride;
  final List<CaptureStroke> ink;

  ScreenCapture withInk(List<CaptureStroke> ink) =>
      ScreenCapture(pixels: pixels, width: width, height: height, stride: stride, ink: ink);
}

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

  /// What is in front and which tools work now (SLIDE_STATE's `front` and
  /// `caps`). Read right after [getSlideState], whose show it describes; it
  /// must be cheap, since the server reads it also between slide states to
  /// notice a new window in front.
  Future<PresenterCaps> capabilities();

  /// Slide [index] (from 1) of the running show as a JPEG [width] pixels
  /// wide: the slide as saved, without the animation step, ink or video on
  /// screen. Null where the program cannot export.
  Future<SlideImage?> exportSlide(int index, int width);

  /// What the audience sees, as raw pixels: the running show's window, or a
  /// PDF viewer or browser in front in full screen. Null when there is none
  /// to take: no such window (or one out of reach, a native Wayland one), a
  /// viewer that is not in full screen (its other tabs and the desktop never
  /// go to a phone), or a black or white screen on.
  Future<ScreenCapture?> captureScreen();

  // Volume
  void volumeUp();
  void volumeDown();
  void volumeMute();
  Future<void> setVolume(int level);

  // Presentation. [keepInk] is the "keep the ink on slide change" setting
  // of the phone that sent the command: false erases the slide's ink before
  // the show moves (where the program would keep it).
  void slideNext({bool keepInk = false});
  void slidePrev({bool keepInk = false});
  Future<void> slideStart({bool keepInk = false});
  Future<void> slideStartAt(int slideNumber, {bool keepInk = false});
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

  /// The screen darkened but for a circle around the laser. Only the
  /// overlay draws it (OverlayInputService); the programs report it fails.
  void modeSpotlight();

  /// A magnifier around the laser; only the Windows overlay has one.
  void modeZoom();

  /// Takes back the overlay's last stroke; the programs have nothing to undo.
  void undoInk();

  /// The last phone left: the overlay puts away everything it shows (dot,
  /// spotlight, cover, ink), which nobody could clear any more; the
  /// programs keep their own.
  void phonesGone();

  /// Moves the presentation of a WPS the user started, which only keys
  /// reach, into the WPS the PC drives, at the same slide when a show ran
  /// (Linux; WPS_TAKE_OVER). Null when done, else why not.
  Future<RemoteError?> takeOverWps();

  /// True when the service renders the laser pointer itself; the server then
  /// feeds [laserPointerMoved] instead of moving the OS cursor.
  bool get handlesLaserPointer;

  /// Laser position relative to the screen (0..1 on both axes).
  void laserPointerMoved(double relX, double relY);

  /// Puts the OS cursor at ([relX], [relY]), fractions of the running
  /// show's window, so that the program's own laser is there (LASER_ABS,
  /// the phone's finger on the slide picture). Nothing while that window is
  /// unknown.
  void moveCursorInShow(double relX, double relY);

  /// Where the laser overlay should go: the running show's window, else the
  /// focused window (a PDF viewer); its monitor is the one used. Null when
  /// unknown: the primary monitor.
  Future<ScreenArea?> laserArea();

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
