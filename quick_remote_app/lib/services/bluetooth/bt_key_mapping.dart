import 'bt_hid_service.dart';

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
  static const int keyW          = 0x1A;
  static const int keyF5         = 0x3E;
  static const int keyEscape     = 0x29;
  static const int keyReturn     = 0x28;
  static const int keyPageUp     = 0x4B;
  static const int keyPageDown   = 0x4E;
  static const int keyHome       = 0x4A;
  static const int keyEnd        = 0x4D;

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
  static BtAction? forCommand(String command) {
    return _map[command];
  }

  static final Map<String, BtAction> _map = {
    // Slide navigation
    'NEXT': _KeyAction(0, [keyPageDown]),
    'PREV': _KeyAction(0, [keyPageUp]),

    // Presentation control
    'START': _KeyAction(0, [keyF5]),
    'END':   _KeyAction(0, [keyEscape]),

    // Screen blanking
    'BLACK_SCREEN': _KeyAction(0, [keyB]),
    'WHITE_SCREEN': _KeyAction(0, [keyW]),

    // Drawing modes — PowerPoint shortcuts
    'MODE_ARROW':       _KeyAction(modLCtrl, [keyA]),
    'MODE_LASER':       _KeyAction(modLCtrl, [keyL]),
    'MODE_PEN':         _KeyAction(modLCtrl, [keyP]),
    'MODE_HIGHLIGHTER': _KeyAction(modLCtrl, [keyI]),
    'MODE_ERASER':      _KeyAction(modLCtrl, [keyE]),
    'LASER_OFF':        _KeyAction(modLCtrl, [keyA]),
    'LASER_CURSOR':     _KeyAction(modLCtrl, [keyL]),

    // Lock PC — Win+L
    'LOCK': _KeyAction(modLGui, [keyL]),

    // Volume
    'VOLUME_UP':   _ConsumerAction(consumerVolumeUp),
    'VOLUME_DOWN': _ConsumerAction(consumerVolumeDown),
    'VOLUME_MUTE': _ConsumerAction(consumerMute),

    // System media transport
    'SYSTEM_MEDIA_PLAY_PAUSE': _ConsumerAction(consumerPlayPause),
    'SYSTEM_MEDIA_NEXT':       _ConsumerAction(consumerNextTrack),
    'SYSTEM_MEDIA_PREV':       _ConsumerAction(consumerPrevTrack),
    'SYSTEM_MEDIA_STOP':       _ConsumerAction(consumerStop),

    // Mouse clicks
    'LEFT_CLICK':  _MouseClickAction(1),
    'RIGHT_CLICK': _MouseClickAction(2),
    // LEFT_DOWN / LEFT_UP not directly mappable in HID without state tracking;
    // map both to a left click for simplicity.
    'LEFT_DOWN': _MouseClickAction(1),
    'LEFT_UP':   _NoopAction(),

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

class _NoopAction extends BtAction {
  @override
  Future<void> execute(BtHidService service) async {}
}
