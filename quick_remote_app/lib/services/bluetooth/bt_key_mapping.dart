import 'package:quick_remote_shared/quick_remote_shared.dart';

import 'bt_hid_service.dart';

/// Presentation program the phone sends keyboard shortcuts to in BT HID mode.
/// Over Bluetooth the phone cannot detect it, so the user picks it. The two
/// sites in a browser are named as the PC's `WebPresenters`.
enum BtTarget {
  powerpoint,
  impress,
  wps,
  powerpointWeb,
  googleSlides;

  static BtTarget fromName(String? name) =>
      values.firstWhere((t) => t.name == name, orElse: () => powerpoint);
}

/// Maps QuickRemote string commands to Bluetooth Classic HID key/consumer reports.
///
/// Usage:
/// ```dart
/// final action = BtKeyMapping.forCommand('NEXT');
/// await action?.execute(BtHidService.instance);
/// ```
abstract class BtKeyMapping {
  // ── HID Key Codes (USB HID Usage Tables §10) ──────────────────────────────
  static const int keyA          = 0x04;
  static const int keyB          = 0x05;
  static const int keyE          = 0x08;
  static const int keyI          = 0x0C;
  static const int keyL          = 0x0F;
  static const int keyP          = 0x13;
  static const int keyR          = 0x15;
  static const int keyU          = 0x18;
  static const int keyW          = 0x1A;
  static const int keyF5         = 0x3E;
  static const int keyEscape     = 0x29;
  static const int keyReturn     = 0x28;
  static const int keyPageUp     = 0x4B;
  static const int keyPageDown   = 0x4E;
  static const int keyHome       = 0x4A;
  static const int keyEnd        = 0x4D;
  static const int keyRight      = 0x4F;
  static const int keyLeft       = 0x50;

  // ── Modifier bits ─────────────────────────────────────────────────────────
  static const int modLCtrl  = 0x01;
  static const int modLShift = 0x02;
  static const int modLAlt   = 0x04;
  static const int modLGui   = 0x08; // Win key

  // ── Consumer Control Usage IDs (USB HID Usage Tables §15) ────────────────
  static const int consumerVolumeUp   = 0x00E9;
  static const int consumerVolumeDown = 0x00EA;
  static const int consumerMute       = 0x00E2;
  static const int consumerPlayPause  = 0x00CD;
  static const int consumerNextTrack  = 0x00B5;
  static const int consumerPrevTrack  = 0x00B6;
  static const int consumerStop       = 0x00B7;

  // ── Mapping ───────────────────────────────────────────────────────────────

  /// Returns the [BtAction] for a given QuickRemote command string, or null
  /// if the command is not supported in BT HID mode.
  static BtAction? forCommand(String command, {BtTarget target = BtTarget.powerpoint}) {
    final overrides = switch (target) {
      BtTarget.powerpoint => _powerpointOverrides,
      BtTarget.impress => _impressOverrides,
      BtTarget.wps => _wpsOverrides,
      BtTarget.powerpointWeb => _powerpointWebOverrides,
      BtTarget.googleSlides => _googleSlidesOverrides,
    };
    return overrides[command] ?? _map[command];
  }

  /// PowerPoint's Ctrl+A leaves the arrow always shown, and with it the
  /// show's toolbar in the corner after the laser or the pen. Ctrl+U right
  /// after makes it the arrow that hides by itself (PointerType 4, what the
  /// Wi-Fi PC sets through COM). Ctrl+U alone toggles between that and a
  /// hidden arrow, so it always follows Ctrl+A, and only MODE_ARROW sends it:
  /// LASER_OFF comes with a MODE_ARROW (the touchpad, the watch), and a second
  /// Ctrl+U would hide the arrow again. Verified on PowerPoint 365,
  /// Windows 11 (2026-10-25).
  static final Map<String, BtAction> _powerpointOverrides = {
    RemoteCommands.modeArrow: _SequenceAction([
      _KeyAction(modLCtrl, [keyA]),
      _KeyAction(modLCtrl, [keyU]),
    ]),
  };

  /// LibreOffice Impress slideshow shortcuts, verified against Impress 26.8:
  /// Ctrl+P toggles the pen, Ctrl+A turns it off, E erases all ink, and
  /// F5/Esc/B/W/PageUp/PageDown behave like PowerPoint. Impress has no
  /// keyboard shortcut for the laser, highlighter or eraser (Ctrl+L/I/E do
  /// nothing in the slideshow and are text formatting in the editor), so those
  /// are no-ops: the laser becomes the plain mouse cursor, and the toolbar
  /// hides highlighter/eraser because a click without the pen advances the slide.
  static final Map<String, BtAction> _impressOverrides = {
    RemoteCommands.modeLaser:       _NoopAction(),
    RemoteCommands.laserCursor:     _NoopAction(),
    RemoteCommands.laserOff:        _NoopAction(),
    RemoteCommands.modeHighlighter: _NoopAction(),
    RemoteCommands.modeEraser:      _NoopAction(),
  };

  /// WPS Presentation slideshow shortcuts, verified against WPS 11.1 on
  /// Linux: F5/Esc/B/W/E/PageUp/PageDown and Ctrl+P/Ctrl+I/Ctrl+E/Ctrl+A
  /// behave like PowerPoint (Ctrl+E is the show's `ShowErase`, an eraser that removes whole strokes). Ctrl+L is
  /// WPS's playback bar. WPS's laser pen is Ctrl+R (its
  /// `LaserPenShortCut`); Ctrl+A first returns to the arrow, so the laser
  /// comes on whatever was on before, and a WPS without the laser keeps the
  /// arrow, moved with the mouse.
  static final Map<String, BtAction> _wpsOverrides = {
    RemoteCommands.modeLaser:   _wpsLaser,
    RemoteCommands.laserCursor: _wpsLaser,
  };

  /// PowerPoint for the web (Microsoft's list of its keys): Ctrl+F5 starts
  /// the show (F5 alone reloads the page), Esc ends it, PageDown/PageUp turn
  /// slides. It has no key for black or white screen, the laser or ink, so
  /// those are no-ops and the laser is the mouse cursor. Not tried yet.
  static final Map<String, BtAction> _powerpointWebOverrides = {
    RemoteCommands.start:           _KeyAction(modLCtrl, [keyF5]),
    RemoteCommands.blackScreen:     _NoopAction(),
    RemoteCommands.whiteScreen:     _NoopAction(),
    RemoteCommands.eraseAll:        _NoopAction(),
    RemoteCommands.modeArrow:       _NoopAction(),
    RemoteCommands.modeLaser:       _NoopAction(),
    RemoteCommands.laserCursor:     _NoopAction(),
    RemoteCommands.laserOff:        _NoopAction(),
    RemoteCommands.modePen:         _NoopAction(),
    RemoteCommands.modeHighlighter: _NoopAction(),
    RemoteCommands.modeEraser:      _NoopAction(),
  };

  /// Google Slides (Google's list of its keys): Ctrl+F5 presents, Esc
  /// stops, the arrows turn slides, B and W blank the screen, L turns its
  /// laser on and off. L is a toggle, so only MODE_LASER and LASER_OFF press
  /// it (the touchpad's finger down and up), not the MODE_ARROW after LASER_OFF.
  /// No ink. Not tried yet.
  static final Map<String, BtAction> _googleSlidesOverrides = {
    RemoteCommands.start:           _KeyAction(modLCtrl, [keyF5]),
    RemoteCommands.next:            _KeyAction(0, [keyRight]),
    RemoteCommands.prev:            _KeyAction(0, [keyLeft]),
    RemoteCommands.eraseAll:        _NoopAction(),
    RemoteCommands.modeArrow:       _NoopAction(),
    RemoteCommands.modeLaser:       _KeyAction(0, [keyL]),
    RemoteCommands.laserCursor:     _KeyAction(0, [keyL]),
    RemoteCommands.laserOff:        _KeyAction(0, [keyL]),
    RemoteCommands.modePen:         _NoopAction(),
    RemoteCommands.modeHighlighter: _NoopAction(),
    RemoteCommands.modeEraser:      _NoopAction(),
  };

  static final BtAction _wpsLaser = _SequenceAction([
    _KeyAction(modLCtrl, [keyA]),
    _KeyAction(modLCtrl, [keyR]),
  ]);

  static final Map<String, BtAction> _map = {
    // Slide navigation
    RemoteCommands.next: _KeyAction(0, [keyPageDown]),
    RemoteCommands.prev: _KeyAction(0, [keyPageUp]),

    // Presentation control
    RemoteCommands.start: _KeyAction(0, [keyF5]),
    RemoteCommands.end:   _KeyAction(0, [keyEscape]),

    // Screen blanking
    RemoteCommands.blackScreen: _KeyAction(0, [keyB]),
    RemoteCommands.whiteScreen: _KeyAction(0, [keyW]),
    RemoteCommands.eraseAll:    _KeyAction(0, [keyE]),

    // Drawing modes — PowerPoint shortcuts
    RemoteCommands.modeArrow:       _KeyAction(modLCtrl, [keyA]),
    RemoteCommands.modeLaser:       _KeyAction(modLCtrl, [keyL]),
    RemoteCommands.modePen:         _KeyAction(modLCtrl, [keyP]),
    RemoteCommands.modeHighlighter: _KeyAction(modLCtrl, [keyI]),
    RemoteCommands.modeEraser:      _KeyAction(modLCtrl, [keyE]),
    RemoteCommands.laserOff:        _KeyAction(modLCtrl, [keyA]),
    RemoteCommands.laserCursor:     _KeyAction(modLCtrl, [keyL]),

    // Lock PC — Win+L
    RemoteCommands.lock: _KeyAction(modLGui, [keyL]),

    // Volume
    RemoteCommands.volumeUp:   _ConsumerAction(consumerVolumeUp),
    RemoteCommands.volumeDown: _ConsumerAction(consumerVolumeDown),
    RemoteCommands.volumeMute: _ConsumerAction(consumerMute),

    // System media transport
    RemoteCommands.sysMediaPlayPause: _ConsumerAction(consumerPlayPause),
    RemoteCommands.sysMediaNext:       _ConsumerAction(consumerNextTrack),
    RemoteCommands.sysMediaPrev:       _ConsumerAction(consumerPrevTrack),
    RemoteCommands.sysMediaStop:       _ConsumerAction(consumerStop),

    // Mouse clicks
    RemoteCommands.leftClick:  _MouseClickAction(1),
    RemoteCommands.rightClick: _MouseClickAction(2),
    // LEFT_DOWN / LEFT_UP not directly mappable in HID without state tracking;
    // map both to a left click for simplicity.
    RemoteCommands.leftDown: _MouseClickAction(1),
    RemoteCommands.leftUp:   _NoopAction(),

    // Commands not supported in BT HID mode (need WiFi + PC app):
    // SET_PEN_COLOR, START_AT, MEDIA_PLAY_PAUSE, MEDIA_REWIND,
    // REFRESH_STATE — omitted intentionally; forCommand() returns null.
  };
}

// ── Action types ──────────────────────────────────────────────────────────────

abstract class BtAction {
  Future<void> execute(BtHidService service);
}

class _KeyAction extends BtAction {
  final int modifier;
  final List<int> keyCodes;
  _KeyAction(this.modifier, this.keyCodes);

  @override
  Future<void> execute(BtHidService service) =>
      service.sendKeyCombo(
        modifier == 0 ? [] : _expandModifier(modifier),
        keyCodes.first,
      );

  static List<int> _expandModifier(int mod) {
    final list = <int>[];
    if (mod & BtKeyMapping.modLCtrl  != 0) list.add(BtKeyMapping.modLCtrl);
    if (mod & BtKeyMapping.modLShift != 0) list.add(BtKeyMapping.modLShift);
    if (mod & BtKeyMapping.modLAlt   != 0) list.add(BtKeyMapping.modLAlt);
    if (mod & BtKeyMapping.modLGui   != 0) list.add(BtKeyMapping.modLGui);
    return list;
  }
}

class _ConsumerAction extends BtAction {
  final int usageId;
  _ConsumerAction(this.usageId);

  @override
  Future<void> execute(BtHidService service) =>
      service.sendConsumerControl(usageId);
}

class _MouseClickAction extends BtAction {
  final int button;
  _MouseClickAction(this.button);

  @override
  Future<void> execute(BtHidService service) =>
      service.sendMouseClick(button: button);
}

/// Runs [actions] one after another.
class _SequenceAction extends BtAction {
  final List<BtAction> actions;
  _SequenceAction(this.actions);

  @override
  Future<void> execute(BtHidService service) async {
    for (final action in actions) {
      await action.execute(service);
    }
  }
}

class _NoopAction extends BtAction {
  @override
  Future<void> execute(BtHidService service) async {}
}
