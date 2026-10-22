import 'dart:io';
import 'package:flutter/foundation.dart';
import '../input_service.dart';
import '../pdf_viewers.dart';
import '../slide_files.dart';
import 'evdev_keys.dart';
import 'impress_bridge.dart';
import 'mpris_controller.dart';
import 'pactl_volume.dart';
import 'script_bridge.dart';
import 'uinput_device.dart';
import 'wps_bridge.dart';
import 'wps_take_over.dart';
import 'x11_windows.dart';

/// Linux implementation: LibreOffice Impress over UNO and WPS Presentation
/// over RPC for presentation features, uinput for keyboard/mouse, pactl for
/// volume, MPRIS for media.
///
/// Presentation commands go to the first program whose show runs: Impress,
/// then the WPS the WPS bridge opened. A WPS the user started is out of the
/// bridge's reach, so it gets WPS's own shortcuts, only while it has the
/// focus. Anything else falls back to plain key presses, so PDF viewers and
/// browser slides still work.
class LinuxInputService implements InputService {
  LinuxInputService()
      : _impress = ImpressBridge.instance,
        _wps = WpsBridge.instance,
        _activeWindow = X11Windows.instance.activeWindow,
        _clientWindows = X11Windows.instance.clientWindows,
        _windowArea = X11Windows.instance.area,
        _captureWindow = X11Windows.instance.capture,
        _windowTitle = X11Windows.instance.title,
        _closeWindow = X11Windows.instance.close,
        _takeOverOverride = null,
        _keys = UinputDevice.instance.combo {
    _device.ensureOpen();
    _impress.onEvent = _onImpressEvent;
  }

  /// With fake bridges, windows and keyboard; the uinput device stays closed.
  @visibleForTesting
  LinuxInputService.withDependencies({
    required ScriptBridge impress,
    required ScriptBridge wps,
    required X11Window? Function() activeWindow,
    required List<X11Window> Function() clientWindows,
    required void Function(List<int> keys) keys,
    ScreenArea? Function(int window)? windowArea,
    ScreenCapture? Function(int window)? captureWindow,
    WpsTakeOver? takeOver,
  })  : _impress = impress,
        _wps = wps,
        _activeWindow = activeWindow,
        _clientWindows = clientWindows,
        _windowArea = windowArea ?? ((_) => null),
        _captureWindow = captureWindow ?? ((_) => null),
        _windowTitle = ((_) => null),
        _closeWindow = ((_) => false),
        _takeOverOverride = takeOver,
        _keys = keys;

  final UinputDevice _device = UinputDevice.instance;
  final ScriptBridge _impress;
  final ScriptBridge _wps;
  final X11Window? Function() _activeWindow;
  final List<X11Window> Function() _clientWindows;
  final ScreenArea? Function(int window) _windowArea;
  final ScreenCapture? Function(int window) _captureWindow;
  final String? Function(int window) _windowTitle;
  final bool Function(int window) _closeWindow;
  final WpsTakeOver? _takeOverOverride;

  late final WpsTakeOver _takeOver = _takeOverOverride ??
      WpsTakeOver(
        clientWindows: _clientWindows,
        title: _windowTitle,
        close: _closeWindow,
        capture: _captureWindow,
        request: _wpsRequest,
        exportPath: SlideFiles.path,
      );

  /// The Impress show's window, from its last state (`window`); null when
  /// unknown or no Impress show runs.
  ScreenArea? _impressArea;

  /// Presses keys together (uinput), then releases them.
  final void Function(List<int> keys) _keys;
  final MprisController _mpris = MprisController();
  final PactlVolume _volume = PactlVolume();

  bool _laserViaImpress = false;
  bool _laserOn = false;

  /// WPS's laser pen is on, turned on with its key (Ctrl+R).
  bool _wpsLaser = false;

  /// Impress draws the highlighter as see-through strokes (its bridge's
  /// strokeBegin/strokeEnd) instead of the ink the mouse button would draw.
  bool _strokesViaImpress = false;
  bool _stroking = false;

  /// The highlighter mode being chosen; the button waits for it, since it
  /// either draws ink or starts a stroke.
  Future<void>? _highlighterMode;

  /// The program whose show the last state read ('impress', 'wps' for the
  /// bridge's WPS), or null: slide pictures come from it.
  String? _showBy;

  /// pid of the WPS the bridge controls, from its last reply.
  int? _wpsRpcPid;

  /// pywpsrpc answered: the bridge can open what a take-over moves.
  bool _wpsRpc = false;

  /// Ink colors (BGR) for WPS, whose single pointer color the pen and the
  /// highlighter share; null until the phone picks one.
  int? _penColor;
  int? _highlighterColor;
  bool _wpsHighlighter = false;
  static const _defaultPenColor = 0x0000FF; // red, BGR

  /// Over a video the laser is hidden behind it, so the bridge has the OS
  /// cursor, which shows above the video, stand in for it.
  void _onImpressEvent(Map<String, dynamic> event) {
    final x = event['x'], y = event['y'];
    if (event['event'] == 'cursor' && x is num && y is num) {
      UinputDevice.pointer.moveAbsolute(x.toDouble(), y.toDouble());
    }
  }

  @override
  CommandErrorHandler? onCommandError;

  @override
  String get presenter => 'impress';

  @override
  List<String> get presenters => const ['impress', 'wps'];

  // ── Presenter lookup ──

  /// The focused window when it belongs to WPS Presentation.
  X11Window? _focusedWps() {
    final window = _activeWindow();
    return window != null && window.hasClass('wpp') ? window : null;
  }

  /// The focused window when it is a WPS slideshow, where Ctrl+A/Ctrl+R are
  /// pointer keys (in the editor they select all and align right).
  X11Window? _focusedWpsShow() {
    final window = _focusedWps();
    return window != null && window.fullscreen ? window : null;
  }

  /// A WPS slideshow (a full-screen WPS Presentation window) is on screen.
  bool _wpsShowOnScreen() => _clientWindows().any((w) => w.hasClass('wpp') && w.fullscreen);

  /// Whether the focused WPS is the one the bridge controls.
  bool _isBridgeWps(X11Window window) => window.pid != null && window.pid == _wpsRpcPid;

  Future<Map<String, dynamic>> _wpsRequest(
    String cmd, [
    Map<String, Object?> args = const {},
    Duration timeout = const Duration(seconds: 6),
  ]) async {
    final reply = await _wps.request(cmd, args, timeout);
    if (reply['pid'] is int) _wpsRpcPid = reply['pid'] as int;
    final error = reply['error'];
    if (error == 'NO_RPC' || reply['rpc'] == false) {
      _wpsRpc = false;
    } else if (reply['ok'] == true || error == 'NOT_RUNNING' || error == 'NO_PRESENTATION') {
      _wpsRpc = true;
    }
    return reply;
  }

  /// Runs [cmd] on Impress, then on the bridge's WPS. Returns null when one
  /// of them ran it, otherwise the two replies.
  Future<(Map<String, dynamic>, Map<String, dynamic>)?> _showCommand(
    String cmd, [
    Map<String, Object?> args = const {},
    Map<String, Object?>? wpsArgs,
    Duration impressTimeout = const Duration(seconds: 6),
  ]) async {
    final impress = await _impress.request(cmd, args, impressTimeout);
    if (impress['ok'] == true) return null;
    final wps = await _wpsRequest(cmd, wpsArgs ?? args);
    if (wps['ok'] == true) return null;
    debugPrint('Presentation "$cmd" failed: Impress ${impress['error']}, WPS ${wps['error']}');
    return (impress, wps);
  }

  /// Runs [cmd]; when no show took it, presses [fallbackKeys] (if any).
  Future<bool> _showOrKeys(
    String cmd, {
    Map<String, Object?> args = const {},
    List<int>? fallbackKeys,
    Duration impressTimeout = const Duration(seconds: 6),
  }) async {
    if (await _showCommand(cmd, args, null, impressTimeout) == null) return true;
    if (fallbackKeys != null) _keys(fallbackKeys);
    return false;
  }

  /// For features without a key: report failures to the phone.
  Future<void> _showOnly(String cmd, {Map<String, Object?> args = const {}, Map<String, Object?>? wpsArgs}) async {
    final failed = await _showCommand(cmd, args, wpsArgs);
    if (failed != null) _report(_describeFailure(failed.$1, failed.$2));
  }

  void _report((RemoteError, String?) failure) => onCommandError?.call(failure.$1, failure.$2);

  /// The error worth showing out of Impress's and WPS's replies.
  (RemoteError, String?) _describeFailure(Map<String, dynamic> impress, Map<String, dynamic> wps) {
    final wpsError = '${wps['error']}';
    const absent = {'NO_RPC', 'NOT_RUNNING', 'NO_PRESENTATION', 'BRIDGE_DIED'};
    if (!absent.contains(wpsError)) return _describeError(wpsError);
    if (_wpsShowOnScreen()) return (RemoteError.wpsOpenFromApp, null);
    return _describeError('${impress['error']}');
  }

  /// Maps a bridge's error code. The bridges and [RemoteError] share most
  /// codes; any other becomes [RemoteError.commandFailed].
  static (RemoteError, String?) _describeError(String error) {
    if (error == 'NO_PYTHON') return (RemoteError.impressNoUno, null);
    final known = RemoteError.fromCode(error);
    if (known != null && known != RemoteError.commandFailed) return (known, null);
    return (RemoteError.commandFailed, error);
  }

  @override
  Future<RemoteError?> takeOverWps() async {
    // A bridge that never answered has not told its WPS's pid yet.
    if (_wpsRpcPid == null) await _wpsRequest('ping');
    return _takeOver.run(bridgePid: _wpsRpcPid);
  }

  // ── States ──
  @override
  Future<Map<String, dynamic>?> getSmtcState() => _mpris.getState();

  @override
  Future<Map<String, dynamic>?> getSlideState() async {
    final impress = await _impress.request('state');
    if (impress['ok'] == true && impress['state'] == 'RUNNING') {
      _showBy = 'impress';
      _impressArea = _area(impress['window']);
      return _slideState(impress, 'impress');
    }
    _showBy = null;
    _impressArea = null;
    _laserViaImpress = false;
    _endStrokes();
    final wps = await _wpsRequest('state');
    if (wps['ok'] == true && wps['state'] == 'RUNNING') {
      _showBy = 'wps';
      return _slideState(wps, 'wps');
    }
    if (_wpsShowOnScreen()) {
      // A WPS the bridge cannot reach: the show runs, its slide is unknown.
      return {
        'current': 0,
        'total': 0,
        'notes': '',
        'hasMedia': false,
        'isMediaPlaying': null,
        'isBlackScreen': false,
        'presenter': 'wps',
      };
    }
    _laserOn = false;
    _wpsLaser = false;
    // No show: the program of the window in front still tells the phone
    // which one to ask the user to start (a WPS editor after a take-over).
    final window = _activeWindow();
    final inFront = window == null
        ? null
        : window.hasClass('wpp')
            ? 'wps'
            : (window.hasClass('libreoffice-impress') || window.hasClass('libreoffice-draw'))
                ? 'impress'
                : null;
    return {'error': 'POWERPOINT_NOT_RUNNING', 'presenter': ?inFront};
  }

  /// The show [getSlideState] last found is the one described: Impress and
  /// the bridge's WPS do everything, a WPS the user started only what its
  /// keys do while it has the focus (no slide number, no pictures), a PDF
  /// viewer or browser only turns pages. Reads only the focused window (and
  /// the window list for a WPS show), so it is cheap enough to poll.
  @override
  Future<PresenterCaps> capabilities() async {
    final window = _activeWindow();
    final front = window == null ? null : _frontOf(window);
    final Set<String> caps;
    switch (_showBy) {
      case 'impress':
        caps = {..._fullShow};
      case 'wps':
        caps = {..._fullShow};
        // WPS 11.1's Player does nothing (Play() leaves a video still, its
        // State always reads playing), as WPS 12.2's on Windows.
        caps.removeAll({RemoteCaps.media, RemoteCaps.rewind});
        // WPS's object model has no highlighter: its Ctrl+I needs the focus.
        if (window == null || !window.hasClass('wpp')) caps.remove(RemoteCaps.highlighter);
      default:
        if (window != null && window.hasClass('wpp') && window.fullscreen) {
          // A WPS the user started: its own keys, it has the focus.
          caps = {
            RemoteCaps.laser,
            RemoteCaps.pen,
            RemoteCaps.highlighter,
            RemoteCaps.eraser,
            RemoteCaps.eraseAll,
            RemoteCaps.blank,
          };
        } else if (front == FrontWindow.editor && !(window!.hasClass('wpp') && !_isBridgeWps(window))) {
          // Impress (or Draw with a PDF) and the bridge's WPS start a show at
          // a slide; the WPS the user started only from its first (F5).
          caps = {RemoteCaps.goto};
        } else {
          caps = {};
        }
    }
    if (_wpsRpc && WpsTakeOver.userWindows(_clientWindows(), _wpsRpcPid).isNotEmpty) {
      caps.add(RemoteCaps.takeOver);
    }
    return PresenterCaps(front: front, caps: caps);
  }

  /// What every show the bridges drive has.
  static const _fullShow = {
    RemoteCaps.laser,
    RemoteCaps.pen,
    RemoteCaps.highlighter,
    RemoteCaps.eraser,
    RemoteCaps.eraseAll,
    RemoteCaps.blank,
    RemoteCaps.goto,
    RemoteCaps.notes,
    RemoteCaps.colors,
    RemoteCaps.media,
    RemoteCaps.rewind,
    RemoteCaps.previews,
  };

  /// The kind of [window] (an X11 window; a native Wayland one is never
  /// seen). LibreOffice's show is a window of the same class as its editor,
  /// so it counts as the show while an Impress show runs.
  String _frontOf(X11Window window) {
    if (window.hasClass('wpp')) return window.fullscreen ? FrontWindow.show : FrontWindow.editor;
    if (window.hasClass('libreoffice-impress') || window.hasClass('libreoffice-draw')) {
      return _showBy == 'impress' ? FrontWindow.show : FrontWindow.editor;
    }
    for (final name in window.wmClass) {
      final kind = PdfViewers.kindOf(name);
      if (kind != null) return kind;
    }
    return FrontWindow.other;
  }

  static ScreenArea? _area(Object? window) {
    if (window is! List || window.length != 4 || window.any((v) => v is! int)) return null;
    final [x, y, width, height] = window.cast<int>();
    return (x: x, y: y, width: width, height: height);
  }

  /// The Impress show's window, else the focused X11 window (a PDF viewer or
  /// a browser under XWayland). A native Wayland window tells nobody where
  /// it is: null, the overlay's primary monitor.
  @override
  Future<ScreenArea?> laserArea() async {
    if (_showBy == 'impress' && _impressArea != null) return _impressArea;
    final window = _activeWindow();
    return window == null ? null : _windowArea(window.id);
  }

  /// The window the audience sees, taken with XCB GetImage: the Impress
  /// show's (its window from the last state, else its full-screen one), a
  /// WPS show (a full-screen WPS Presentation window, the bridge's or the
  /// user's), else the focused PDF viewer or browser when it is in full
  /// screen. A native Wayland window is out of X11's reach: null.
  @override
  Future<ScreenCapture?> captureScreen() async {
    final window = _audienceWindow();
    return window == null ? null : _captureWindow(window.id);
  }

  X11Window? _audienceWindow() {
    if (_showBy == 'impress') {
      final impress = _clientWindows().where((w) => w.hasClass('libreoffice-impress')).toList();
      final area = _impressArea;
      return (area == null ? null : impress.where((w) => _windowArea(w.id) == area).firstOrNull) ??
          impress.where((w) => w.fullscreen).firstOrNull;
    }
    final wpsShow = _clientWindows().where((w) => w.hasClass('wpp') && w.fullscreen).firstOrNull;
    if (wpsShow != null) return wpsShow;
    if (_showBy != null) return null;
    final focused = _activeWindow();
    if (focused == null || !focused.fullscreen || !FrontWindow.isViewer(_frontOf(focused))) return null;
    return focused;
  }

  static Map<String, dynamic> _slideState(Map<String, dynamic> reply, String presenter) => {
        'current': reply['current'],
        'total': reply['total'],
        'notes': reply['notes'] ?? '',
        'hasMedia': reply['hasMedia'] ?? false,
        'isMediaPlaying': reply['isMediaPlaying'],
        'isBlackScreen': reply['isBlackScreen'] ?? false,
        'presenter': presenter,
        'deckKey': reply['deckKey'],
      };

  @override
  Future<VolumeState?> getVolumeState() => _volume.getState();

  /// The program running the show exports the slide (its bridge's
  /// `export`): Impress, or the WPS the bridge opened. The WPS the user
  /// started cannot be reached, and PDF viewers have no slides to export.
  @override
  Future<SlideImage?> exportSlide(int index, int width) async {
    final by = _showBy;
    if (by == null) return null;
    final path = await SlideFiles.path(index, width);
    final args = {'index': index, 'width': width, 'path': path};
    final reply = by == 'impress'
        ? await _impress.request('export', args, const Duration(seconds: 5))
        : await _wpsRequest('export', args);
    final height = reply['height'];
    if (reply['ok'] != true || height is! int || height < 1) {
      await SlideFiles.discard(path);
      return null;
    }
    return SlideFiles.read(path, width, height);
  }

  // ── Volume ──
  @override
  void volumeUp() => _volume.change(PactlVolume.step);
  @override
  void volumeDown() => _volume.change(-PactlVolume.step);
  @override
  void volumeMute() => _volume.toggleMute();
  @override
  Future<void> setVolume(int level) => _volume.setLevel(level);

  // ── Presentation ──
  @override
  void slideNext({bool keepInk = false}) =>
      _showOrKeys('next', args: _inkArgs(keepInk), fallbackKeys: _pageKeys(next: true));
  @override
  void slidePrev({bool keepInk = false}) =>
      _showOrKeys('prev', args: _inkArgs(keepInk), fallbackKeys: _pageKeys(next: false));

  /// PageDown/PageUp, or the focused viewer's own page keys (the arrows in
  /// browsers and WPS PDF, whose PageDown scrolls by a screen).
  List<int> _pageKeys({required bool next}) {
    final window = _activeWindow();
    final viewer = window == null ? null : _viewerOf(window);
    final keys = next ? viewer?.next : viewer?.prev;
    if (keys != null) return _evdev(keys);
    return [next ? Evdev.keyPageDown : Evdev.keyPageUp];
  }

  /// The bridges erase the slide's ink before the show moves unless the
  /// phone that sent the command keeps it.
  static Map<String, Object?> _inkArgs(bool keepInk) => {'clearInk': !keepInk};

  @override
  Future<void> slideStart({bool keepInk = false}) => _start('start', _inkArgs(keepInk));

  @override
  Future<void> slideStartAt(int slideNumber, {bool keepInk = false}) =>
      // Without a bridge there is no way to tell whether F5 opened a show, and
      // typing the number + Enter into any other window could send a chat
      // message. So the key fallback only starts the show from its first slide.
      _start('startAt', {'slide': slideNumber, ..._inkArgs(keepInk)});

  /// Starts the show of the focused WPS or PDF viewer, or else of Impress
  /// (a PDF open in Draw becomes a presentation there) or the bridge's WPS;
  /// F5 when none of them can.
  Future<void> _start(String cmd, Map<String, Object?> args) async {
    final window = _activeWindow();
    if (window != null && window.hasClass('wpp')) {
      if (!_isBridgeWps(window) || (await _wpsRequest(cmd, args))['ok'] != true) {
        _keys([Evdev.keyF5]);
      }
      return;
    }
    final viewer = window == null ? null : _viewerOf(window);
    if (viewer != null) {
      _keys(_evdev(viewer.start));
      final end = viewer.end;
      _toggled = end == null ? null : (window!.id, end);
      return;
    }
    await _showOrKeys(cmd,
        args: args, fallbackKeys: [Evdev.keyF5], impressTimeout: const Duration(seconds: 65));
  }

  /// The X11 window a START toggled a mode on in (a browser's full screen),
  /// and the keys with which END toggles it off there.
  (int, List<int>)? _toggled;

  static ViewerKeys? _viewerOf(X11Window window) {
    for (final name in window.wmClass) {
      final viewer = PdfViewers.forProgram(name);
      if (viewer != null) return viewer;
    }
    return null;
  }

  static List<int> _evdev(List<int> vks) => [for (final vk in vks) Evdev.fromVk(vk)!];

  @override
  Future<void> slideEnd() async {
    _laserViaImpress = false;
    _endStrokes();
    _laserOn = false;
    _wpsLaser = false;
    final toggled = _toggled;
    _toggled = null;
    if (toggled != null && _activeWindow()?.id == toggled.$1) {
      _keys(_evdev(toggled.$2));
      return;
    }
    await _showOrKeys('end', fallbackKeys: [Evdev.keyEsc]);
  }

  @override
  void blackScreen() => _showOrKeys('blank', args: {'color': 0x000000}, fallbackKeys: [Evdev.keyB]);
  @override
  void whiteScreen() => _showOrKeys('blank', args: {'color': 0xFFFFFF}, fallbackKeys: [Evdev.keyW]);

  @override
  Future<void> eraseAllInk() async {
    final failed = await _showCommand('eraseAll');
    if (failed == null) return;
    if (_focusedWps() != null) {
      _keys([Evdev.keyE]); // WPS's own "erase all ink" key
      return;
    }
    _report(_describeFailure(failed.$1, failed.$2));
  }

  @override
  Future<void> setPenColor(int bgrColor) {
    _penColor = bgrColor;
    return _showOnly('penColor', args: {'rgb': _rgb(bgrColor)}, wpsArgs: {'bgr': bgrColor});
  }

  @override
  Future<void> setHighlighterColor(int bgrColor) async {
    _highlighterColor = bgrColor;
    final reply = await _impress.request('highlighterColor', {'rgb': _rgb(bgrColor)});
    if (reply['ok'] == true) return;
    // WPS's highlighter takes the color when it is next chosen (Ctrl+I).
    if (_wpsHighlighter) await _wpsRequest('pointerColor', {'bgr': bgrColor});
  }

  /// PowerPoint and WPS use BGR, UNO uses RGB.
  static int _rgb(int bgr) => ((bgr & 0xFF) << 16) | (bgr & 0xFF00) | ((bgr >> 16) & 0xFF);

  @override
  Future<void> pptMediaPlayPause() => _showOnly('mediaToggle');
  @override
  Future<void> pptMediaRewind() => _showOnly('mediaRewind');

  // ── Modes ──
  @override
  void toggleLaserCursor() => _laserOn ? laserOff() : modeLaser();

  @override
  void modeArrow() => _setMode('arrow', wpsKeys: [Evdev.keyLeftCtrl, Evdev.keyA]);

  @override
  void modePen() => _setMode(
        'pen',
        // After the highlighter, the shared pointer color is the highlighter's.
        wpsArgs: {'bgr': _penColor ?? (_highlighterColor == null ? null : _defaultPenColor)},
        wpsKeys: [Evdev.keyLeftCtrl, Evdev.keyP],
      );

  @override
  void modeEraser() => _setMode('eraser', wpsKeys: [Evdev.keyLeftCtrl, Evdev.keyE]);

  // Only the overlay has a spotlight and strokes to take back.
  @override
  void modeSpotlight() => onCommandError?.call(RemoteError.commandFailed, 'NO_SPOTLIGHT');
  @override
  void modeZoom() => onCommandError?.call(RemoteError.commandFailed, 'NO_ZOOM');

  @override
  void undoInk() {}

  @override
  void phonesGone() {}

  @override
  void laserOff() => _setMode('laserOff', wpsKeys: const []);

  @override
  Future<void> modeHighlighter() => _highlighterMode = _modeHighlighter();

  Future<void> _modeHighlighter() async {
    _laserViaImpress = false;
    _laserOn = false;
    _wpsLaser = false;
    // Like the laser, the motion goes to Impress before its reply.
    _strokesViaImpress = true;
    final reply = await _impress.request('highlighter');
    _strokesViaImpress = reply['ok'] == true && reply['strokes'] == true;
    if (reply['ok'] == true) return;
    // WPS's object model has no highlighter: only its Ctrl+I reaches it.
    final focused = _focusedWps();
    if (focused == null) {
      _report(_wpsShowOnScreen() || _wpsRpcPid != null
          ? (RemoteError.wpsHighlighterNeedsFocus, null)
          : _describeError('${reply['error']}'));
      return;
    }
    _keys([Evdev.keyLeftCtrl, Evdev.keyI]);
    _wpsHighlighter = true;
    final color = _highlighterColor;
    if (color != null && _isBridgeWps(focused)) {
      await Future.delayed(const Duration(milliseconds: 100));
      await _wpsRequest('pointerColor', {'bgr': color});
    }
  }

  @override
  Future<void> modeLaser() async {
    // Route the motion to Impress at once: the bridge handles laserOn before
    // any pointer update sent after it. Waiting for the reply would move the
    // real cursor meanwhile.
    _laserViaImpress = true;
    _wpsHighlighter = false;
    _endStrokes();
    // Created ahead of the first video: a new device misses its first events.
    UinputDevice.pointer.ensureOpen();
    final reply = await _impress.request('laserOn');
    if (reply['ok'] == true) {
      _laserOn = true;
      return;
    }
    _laserViaImpress = false;
    // WPS's laser pen has a key (Ctrl+R) but no counterpart in its object
    // model, so it reaches only a focused show. Ctrl+A first returns to the
    // arrow, so the laser comes on whatever was on before.
    if (_focusedWpsShow() != null) {
      _keys([Evdev.keyLeftCtrl, Evdev.keyA]);
      _keys([Evdev.keyLeftCtrl, Evdev.keyR]);
      _laserOn = true;
      _wpsLaser = true;
      return;
    }
    // Elsewhere the server moves the bridge's WPS's visible arrow instead.
    final wps = await _wpsRequest('laserOn');
    if (wps['ok'] == true) {
      _laserOn = true;
    } else if (_focusedWps() != null) {
      _keys([Evdev.keyLeftCtrl, Evdev.keyA]);
      _laserOn = true;
    } else {
      _report(_describeFailure(reply, wps));
    }
  }

  /// Switches the pointer mode on Impress or the bridge's WPS, or presses
  /// [wpsKeys] in a focused WPS (null: the mode has no key there).
  Future<void> _setMode(String cmd, {Map<String, Object?>? wpsArgs, List<int>? wpsKeys}) async {
    _laserViaImpress = false;
    _laserOn = false;
    _wpsHighlighter = false;
    _endStrokes();
    // The bridge's pointer types and LASER_OFF's no key leave WPS's laser on.
    if (_wpsLaser) {
      _wpsLaser = false;
      if (_focusedWpsShow() != null) _keys([Evdev.keyLeftCtrl, Evdev.keyA]);
    }
    final failed = await _showCommand(cmd, const {}, wpsArgs);
    if (failed == null) return;
    if (_focusedWps() != null) {
      if (wpsKeys == null) {
        onCommandError?.call(RemoteError.wpsOpenFromApp);
      } else if (wpsKeys.isNotEmpty) {
        _keys(wpsKeys);
      }
      return;
    }
    _report(_describeFailure(failed.$1, failed.$2));
  }

  void _endStrokes() {
    _strokesViaImpress = false;
    _highlighterMode = null;
  }

  @override
  bool get handlesLaserPointer => _laserViaImpress;

  @override
  void laserPointerMoved(double relX, double relY) {
    // No throttling here: the bridge applies only the newest waiting
    // position, and dropping updates would lose the final one.
    _impress.send('pointer', {'x': relX, 'y': relY});
  }

  @override
  bool get handlesDrawPointer => _strokesViaImpress;

  // The bridge draws the stroke through every position it is sent.
  @override
  void drawPointerMoved(double relX, double relY) => _impress.send('pointer', {'x': relX, 'y': relY});

  // ── Mouse & keyboard ──
  @override
  void leftClick() => _device.click(Evdev.btnLeft);
  @override
  void rightClick() => _device.click(Evdev.btnRight);
  @override
  void leftDown() => _afterHighlighterMode(() {
        if (_strokesViaImpress) {
          _stroking = true;
          _impress.send('strokeBegin', const {});
        } else {
          _device.button(Evdev.btnLeft, down: true);
        }
      });
  @override
  void leftUp() => _afterHighlighterMode(() {
        if (_stroking) {
          _stroking = false;
          _impress.send('strokeEnd', const {});
        } else {
          _device.button(Evdev.btnLeft, down: false);
        }
      });

  /// Runs [action] once the highlighter mode being chosen is known; in
  /// order, so the button never goes up before it went down.
  void _afterHighlighterMode(void Function() action) {
    final mode = _highlighterMode;
    if (mode == null) {
      action();
    } else {
      mode.catchError((_) {}).then((_) => action());
    }
  }

  // ── System ──
  @override
  Future<void> lockPC() async {
    for (final (exe, args) in const [
      ('loginctl', ['lock-session']),
      ('xdg-screensaver', ['lock']),
    ]) {
      try {
        final result = await Process.run(exe, args);
        if (result.exitCode == 0) return;
      } catch (_) {}
    }
    onCommandError?.call(RemoteError.lockFailed);
  }

  Future<void> _media(String method, int fallbackKey) async {
    if (!await _mpris.call(method)) _device.tap(fallbackKey);
  }

  @override
  void sysMediaPlayPause() => _media('PlayPause', Evdev.keyPlayPause);
  @override
  void sysMediaNext() => _media('Next', Evdev.keyNextSong);
  @override
  void sysMediaPrev() => _media('Previous', Evdev.keyPreviousSong);
  @override
  void sysMediaStop() => _media('Stop', Evdev.keyStopCd);
}
