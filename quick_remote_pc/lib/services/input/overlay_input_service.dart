import 'dart:math' as math;

import '../overlay/laser_overlay.dart';
import 'input_service.dart';

/// A stroke as the overlay drew it: positions are fractions of its monitor.
class InkStroke {
  InkStroke({required this.highlighter, required this.rgb, required this.points});

  final bool highlighter;

  /// 0xRRGGBB.
  final int rgb;
  final List<(double, double)> points;
}

enum _InkTool { pen, highlighter, eraser }

/// Wraps the platform [InputService] and draws the laser and the ink on
/// QuickRemote's [LaserOverlay] instead of with the program's own tools,
/// where that is better ([LaserOverlaySettings.mode]): in Impress (its
/// laser and ink go behind a video, its highlighter needs LibreOffice 26.8),
/// in PDF viewers and browsers (no tools at all) and outside a slideshow.
/// PowerPoint and WPS keep their own ([ownLaser]). Every other command goes
/// to the platform service unchanged.
///
/// The strokes are kept here, not in the overlay: the eraser takes away the
/// strokes it touches, and with "keep the ink" (the sending phone's
/// SET_KEEP_INK, passed with each slide command) a slide's
/// strokes come back when the show returns to it. The overlay is only told
/// to clear and draw them again.
class OverlayInputService implements InputService {
  OverlayInputService(this._inner, this._overlay);

  final InputService _inner;
  final LaserOverlay _overlay;

  /// Programs whose own tools work well; the overlay stays away in auto.
  static const ownLaser = {'powerpoint', 'wps'};

  /// How near (fractions of the screen) the eraser takes a stroke away.
  static const eraserReach = 0.015;

  /// The program running the show, from the last slide state read; null
  /// while none runs.
  String? _showBy;

  /// The overlay's dot is up (MODE_LASER went to it).
  bool _overlayLaser = false;

  /// The overlay's spotlight is on (MODE_SPOTLIGHT).
  bool _spotlight = false;

  /// The overlay's magnifier is on (MODE_ZOOM).
  bool _zoom = false;

  /// The overlay covers the screen in this color (BLACK/WHITE_SCREEN
  /// outside a show); null: it does not.
  int? _blank;

  /// The show's own black or white screen is on (its slide state says so):
  /// the overlay's ink, which would show on top of it, is put away.
  bool _showBlank = false;

  /// The tool drawing on the overlay; null while the program's or none is.
  _InkTool? _inkTool;
  bool _stroking = false;
  double _x = 0.5;
  double _y = 0.5;

  /// BGR, as the phones send them; red and yellow, the phone's first ones.
  int _penBgr = 0x0000FF;
  int _highlighterBgr = 0x00FFFF;

  List<InkStroke> _strokes = [];

  /// The slide the ink on screen belongs to ('deck#slide'); null outside a
  /// show and right after a slide command, until the next state.
  String? _page;

  /// Strokes of the slides the show left, by page, while the ink is kept.
  final Map<String, List<InkStroke>> _kept = {};

  /// The keepInk of the last slide command: the phone that turned the slide
  /// decides, also for the page the next slide state brings.
  bool _keepInk = false;

  /// The strokes on screen now.
  List<InkStroke> get strokes => List.unmodifiable(_strokes);

  /// The laser and the ink work outside a slideshow too: the overlay presses
  /// no key. Sent to the phones in the auth reply (`overlay`).
  bool get toolsAnywhere => _overlayAvailable;

  /// The overlay has a magnifier (Windows): MODE_ZOOM works. Sent to the
  /// phones in the auth reply (`zoom`).
  bool get zoomAvailable => _overlayAvailable && _overlay.supportsZoom;

  bool get _overlayAvailable => _overlay.supported && LaserOverlaySettings.mode != LaserOverlayMode.never;

  bool get _useOverlay {
    if (!_overlay.supported) return false;
    return switch (LaserOverlaySettings.mode) {
      LaserOverlayMode.never => false,
      LaserOverlayMode.always => true,
      LaserOverlayMode.auto => !ownLaser.contains(_showBy),
    };
  }

  bool get _showRunning => _showBy != null;

  /// Puts away the overlay's dot, spotlight and magnifier.
  void _hideOverlay() {
    if (_spotlight) {
      _spotlight = false;
      _overlay.spotlight(false);
    }
    if (_zoom) {
      _zoom = false;
      _overlay.zoom(false);
    }
    if (!_overlayLaser) return;
    _overlayLaser = false;
    _overlay.hide();
  }

  @override
  CommandErrorHandler? get onCommandError => _inner.onCommandError;
  @override
  set onCommandError(CommandErrorHandler? handler) => _inner.onCommandError = handler;

  @override
  String get presenter => _inner.presenter;
  @override
  List<String> get presenters => _inner.presenters;

  @override
  Future<Map<String, dynamic>?> getSlideState() async {
    final state = await _inner.getSlideState();
    final running = state != null && !state.containsKey('error');
    _showBy = running ? state['presenter'] as String? ?? _inner.presenter : null;
    if (running) {
      // The show's own black screen from here on.
      _unblank();
      final current = state['current'];
      // A show that does not tell its slide (current 0) keeps one page.
      _turnPage('${state['deckKey'] ?? ''}#${current is int ? current : 0}');
      _followShowBlank(state['isBlackScreen'] == true);
    } else if (_page != null || _kept.isNotEmpty) {
      _turnPage(null);
      _kept.clear();
    }
    if (!running) _showBlank = false;
    return state;
  }

  @override
  Future<Map<String, dynamic>?> getSmtcState() => _inner.getSmtcState();
  @override
  Future<VolumeState?> getVolumeState() => _inner.getVolumeState();
  @override
  Future<SlideImage?> exportSlide(int index, int width) => _inner.exportSlide(index, width);

  /// The program's picture of the screen with the overlay's ink drawn on
  /// it (its strokes are fractions of the overlay's monitor, which the show
  /// or the full-screen viewer covers). None while a black or white screen
  /// is on, the show's or the overlay's: the picture would show the slide
  /// the audience does not see, and the phone covers its own.
  @override
  Future<ScreenCapture?> captureScreen() async {
    if (_blank != null || _showBlank) return null;
    final capture = await _inner.captureScreen();
    if (capture == null || _strokes.isEmpty || _blank != null || _showBlank) {
      return _blank != null || _showBlank ? null : capture;
    }
    return capture.withInk([
      for (final stroke in _strokes)
        (highlighter: stroke.highlighter, rgb: stroke.rgb, points: List.of(stroke.points)),
    ]);
  }

  /// The program's caps, and what the overlay adds: the laser and the ink
  /// where it draws them (outside a show too), its black and white screen
  /// outside a show, the spotlight wherever it runs, the magnifier where it
  /// has one.
  @override
  Future<PresenterCaps> capabilities() async {
    final caps = await _inner.capabilities();
    if (!_overlayAvailable) return caps;
    return caps.plus({
      if (_useOverlay) ...const [
        RemoteCaps.laser,
        RemoteCaps.pen,
        RemoteCaps.highlighter,
        RemoteCaps.eraser,
        RemoteCaps.eraseAll,
        RemoteCaps.colors,
        RemoteCaps.undo,
      ],
      if (!_showRunning) RemoteCaps.blank,
      RemoteCaps.spotlight,
      if (zoomAvailable) RemoteCaps.zoom,
    });
  }

  /// Puts the overlay on the show's monitor; a monitor change would drop
  /// ink already drawn, so it stays where it is then.
  Future<bool> _place() async {
    if (_strokes.isNotEmpty) return _overlay.place(null, keep: true);
    return _overlay.place(await _inner.laserArea());
  }

  // ── Laser ──

  @override
  Future<void> modeLaser() async {
    _endInk();
    if (!_useOverlay) {
      _hideOverlay();
      _inner.modeLaser();
      return;
    }
    // At once: the motion that follows goes to the overlay, not the cursor.
    _overlayLaser = true;
    if (await _place()) {
      _overlay.show();
      return;
    }
    _overlayLaser = false;
    if (_showRunning) {
      _inner.modeLaser();
    } else {
      onCommandError?.call(RemoteError.slideshowNotRunning);
    }
  }

  @override
  Future<void> modeSpotlight() async {
    _endInk();
    if (!_overlayAvailable) {
      _inner.modeSpotlight(); // reports that there is none
      return;
    }
    // No program has one: the overlay draws it in PowerPoint and WPS too.
    _hideOverlay();
    _spotlight = true;
    if (await _place()) {
      _overlay.spotlight(true);
      return;
    }
    _spotlight = false;
    _inner.modeSpotlight();
  }

  @override
  Future<void> modeZoom() async {
    _endInk();
    if (!zoomAvailable) {
      _inner.modeZoom(); // reports that there is none
      return;
    }
    _hideOverlay();
    _zoom = true;
    if (await _place()) {
      _overlay.zoom(true);
      return;
    }
    _zoom = false;
    _inner.modeZoom();
  }

  /// The dot, the spotlight or the magnifier follows the laser's motion.
  bool get _overlayPointer => _overlayLaser || _spotlight || _zoom;

  @override
  void laserOff() {
    if (_overlayPointer) {
      _hideOverlay();
    } else if (_showRunning) {
      _inner.laserOff();
    }
  }

  @override
  void toggleLaserCursor() {
    if (_overlayPointer) {
      _hideOverlay();
    } else if (_useOverlay) {
      modeLaser();
    } else if (_showRunning) {
      _inner.toggleLaserCursor();
    }
  }

  @override
  void modeArrow() {
    _hideOverlay();
    _endInk();
    // Outside a show the arrow is already on, and the program's keys would
    // go to whatever window has the focus.
    if (_showRunning) _inner.modeArrow();
  }

  @override
  Future<ScreenArea?> laserArea() => _inner.laserArea();

  @override
  bool get handlesLaserPointer => _overlayPointer || _inner.handlesLaserPointer;

  @override
  void laserPointerMoved(double relX, double relY) {
    if (_overlayPointer) {
      _overlay.move(relX, relY);
    } else {
      _inner.laserPointerMoved(relX, relY);
    }
  }

  // ── Ink ──

  @override
  Future<void> modePen() => _modeInk(_InkTool.pen, _inner.modePen);

  @override
  Future<void> modeHighlighter() => _modeInk(_InkTool.highlighter, _inner.modeHighlighter);

  @override
  Future<void> modeEraser() => _modeInk(_InkTool.eraser, _inner.modeEraser);

  Future<void> _modeInk(_InkTool tool, void Function() programs) async {
    _hideOverlay();
    _endInk();
    if (!_useOverlay) {
      programs();
      return;
    }
    // At once: the motion and LEFT_DOWN that follow go to the overlay.
    _inkTool = tool;
    if (await _place()) return;
    if (_inkTool == tool) _inkTool = null;
    if (_showRunning) {
      programs();
    } else {
      onCommandError?.call(RemoteError.slideshowNotRunning);
    }
  }

  void _endInk() {
    if (_stroking && _inkTool != _InkTool.eraser) _overlay.inkEnd();
    _stroking = false;
    _inkTool = null;
  }

  @override
  bool get handlesDrawPointer => _inkTool != null || _inner.handlesDrawPointer;

  @override
  void drawPointerMoved(double relX, double relY) {
    if (_inkTool == null) {
      _inner.drawPointerMoved(relX, relY);
      return;
    }
    _x = relX;
    _y = relY;
    if (!_stroking) return;
    if (_inkTool == _InkTool.eraser) {
      _eraseAt(relX, relY);
      return;
    }
    if (_strokes.isEmpty) return;
    _strokes.last.points.add((relX, relY));
    _overlay.inkTo(relX, relY);
  }

  @override
  void leftDown() {
    final tool = _inkTool;
    if (tool == null) {
      _inner.leftDown();
      return;
    }
    // No click reaches the PC: the button only starts a stroke.
    _stroking = true;
    if (tool == _InkTool.eraser) {
      _eraseAt(_x, _y);
      return;
    }
    final highlighter = tool == _InkTool.highlighter;
    final rgb = _rgb(highlighter ? _highlighterBgr : _penBgr);
    _strokes.add(InkStroke(highlighter: highlighter, rgb: rgb, points: [(_x, _y)]));
    _overlay.inkBegin(highlighter: highlighter, rgb: rgb, relX: _x, relY: _y);
  }

  @override
  void leftUp() {
    if (_inkTool == null && !_stroking) {
      _inner.leftUp();
      return;
    }
    if (_stroking && _inkTool != _InkTool.eraser) _overlay.inkEnd();
    _stroking = false;
  }

  /// Takes away every stroke that passes within [eraserReach] of (x, y).
  void _eraseAt(double x, double y) {
    final before = _strokes.length;
    _strokes.removeWhere((stroke) => _touches(stroke, x, y));
    if (_strokes.length != before) _drawAgain();
  }

  static bool _touches(InkStroke stroke, double x, double y) {
    final points = stroke.points;
    if (points.length == 1) return _distance(x, y, points[0], points[0]) <= eraserReach;
    for (var i = 1; i < points.length; i++) {
      if (_distance(x, y, points[i - 1], points[i]) <= eraserReach) return true;
    }
    return false;
  }

  /// From (x, y) to the segment a-b.
  static double _distance(double x, double y, (double, double) a, (double, double) b) {
    final (ax, ay) = a;
    final (bx, by) = b;
    final dx = bx - ax, dy = by - ay;
    final length = dx * dx + dy * dy;
    final t = length == 0 ? 0.0 : (((x - ax) * dx + (y - ay) * dy) / length).clamp(0.0, 1.0);
    final px = ax + t * dx - x, py = ay + t * dy - y;
    return math.sqrt(px * px + py * py);
  }

  void _followShowBlank(bool blank) {
    if (blank == _showBlank) return;
    _showBlank = blank;
    if (_strokes.isEmpty) return;
    if (blank) {
      _overlay.inkClear();
    } else {
      _drawAgain();
    }
  }

  /// Clears the overlay and draws [_strokes] on it again.
  void _drawAgain() {
    _overlay.inkClear();
    for (final stroke in _strokes) {
      final (x, y) = stroke.points.first;
      _overlay.inkBegin(highlighter: stroke.highlighter, rgb: stroke.rgb, relX: x, relY: y);
      for (final (x, y) in stroke.points.skip(1)) {
        _overlay.inkTo(x, y);
      }
      _overlay.inkEnd();
    }
  }

  void _clearInk() {
    if (_strokes.isEmpty) return;
    _strokes = [];
    _stroking = false;
    _overlay.inkClear();
  }

  /// The show moved to [page] (null: left the slide, or no show): its ink
  /// is kept or dropped, the new slide's kept ink comes back. [leaving]: a
  /// slide command, which drops the ink also where no slide is known (a PDF).
  void _turnPage(String? page, {bool leaving = false}) {
    if (page == _page && !leaving) return;
    final keep = _keepInk;
    if (_strokes.isNotEmpty) {
      if (keep && _page != null) _kept[_page!] = _strokes;
      _strokes = [];
      _stroking = false;
      _overlay.inkClear();
    }
    _page = page;
    final back = page == null || !keep ? null : _kept.remove(page);
    if (back != null && back.isNotEmpty) {
      _strokes = back;
      _drawAgain();
    }
  }

  @override
  void undoInk() {
    if (_strokes.isEmpty) {
      _inner.undoInk();
      return;
    }
    _strokes.removeLast();
    _stroking = false;
    _drawAgain();
  }

  @override
  void phonesGone() {
    _hideOverlay();
    _endInk();
    _clearInk();
    _kept.clear();
    _unblank();
    _inner.phonesGone();
  }

  @override
  void eraseAllInk() {
    _clearInk();
    if (_page != null) _kept.remove(_page);
    // The program's own ink, unless the overlay draws instead of it.
    if (!_useOverlay) _inner.eraseAllInk();
  }

  @override
  Future<void> setPenColor(int bgrColor) async {
    _penBgr = bgrColor;
    if (!_useOverlay) await _inner.setPenColor(bgrColor);
  }

  @override
  Future<void> setHighlighterColor(int bgrColor) async {
    _highlighterBgr = bgrColor;
    if (!_useOverlay) await _inner.setHighlighterColor(bgrColor);
  }

  /// The phones send BGR (PowerPoint's order).
  static int _rgb(int bgr) => ((bgr & 0xFF) << 16) | (bgr & 0xFF00) | ((bgr >> 16) & 0xFF);

  // ── Slides: the ink on screen belongs to the slide it was drawn on ──

  // ── Black and white screen: the program's in a show, the overlay's
  // outside one (a PDF in a browser has none) ──

  @override
  Future<void> blackScreen() => _blankOr(0x000000, _inner.blackScreen);

  @override
  Future<void> whiteScreen() => _blankOr(0xFFFFFF, _inner.whiteScreen);

  /// Toggles the overlay's [rgb] screen, as the programs' B and W do.
  Future<void> _blankOr(int rgb, void Function() programs) async {
    if (_showRunning || !_overlayAvailable) {
      programs();
      return;
    }
    final blank = _blank = _blank == rgb ? null : rgb;
    if (blank == null) {
      _overlay.blank(null);
    } else if (await _place() && _blank == blank) {
      _overlay.blank(blank);
    }
  }

  void _unblank() {
    if (_blank == null) return;
    _blank = null;
    _overlay.blank(null);
  }

  @override
  void slideNext({bool keepInk = false}) {
    _unblank();
    _keepInk = keepInk;
    _turnPage(null, leaving: true);
    _inner.slideNext(keepInk: keepInk);
  }

  @override
  void slidePrev({bool keepInk = false}) {
    _unblank();
    _keepInk = keepInk;
    _turnPage(null, leaving: true);
    _inner.slidePrev(keepInk: keepInk);
  }

  @override
  Future<void> slideStartAt(int slideNumber, {bool keepInk = false}) {
    _unblank();
    _keepInk = keepInk;
    _turnPage(null, leaving: true);
    return _inner.slideStartAt(slideNumber, keepInk: keepInk);
  }

  @override
  Future<void> slideEnd() {
    _unblank();
    _hideOverlay();
    _endInk();
    _turnPage(null, leaving: true);
    _kept.clear();
    return _inner.slideEnd();
  }

  // ── Everything else, unchanged ──

  @override
  void volumeUp() => _inner.volumeUp();
  @override
  void volumeDown() => _inner.volumeDown();
  @override
  void volumeMute() => _inner.volumeMute();
  @override
  Future<void> setVolume(int level) => _inner.setVolume(level);

  @override
  Future<void> slideStart({bool keepInk = false}) {
    _unblank();
    _keepInk = keepInk;
    return _inner.slideStart(keepInk: keepInk);
  }

  @override
  Future<void> pptMediaPlayPause() => _inner.pptMediaPlayPause();
  @override
  Future<void> pptMediaRewind() => _inner.pptMediaRewind();

  @override
  void leftClick() => _inner.leftClick();
  @override
  void rightClick() => _inner.rightClick();

  @override
  void lockPC() => _inner.lockPC();
  @override
  void sysMediaPlayPause() => _inner.sysMediaPlayPause();
  @override
  void sysMediaNext() => _inner.sysMediaNext();
  @override
  void sysMediaPrev() => _inner.sysMediaPrev();
  @override
  void sysMediaStop() => _inner.sysMediaStop();
}
