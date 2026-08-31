/// Centralized command and message type constants shared between
/// the mobile app and the PC companion.
///
/// Both quick_remote_app and quick_remote_pc have an identical copy
/// of this file because they are independent Flutter projects.
abstract class RemoteCommands {
  // Slide / presentation controls
  static const next = 'NEXT';
  static const prev = 'PREV';
  static const start = 'START';
  static const end = 'END';
  static const lock = 'LOCK';
  static const clearInk = 'CLEAR_INK';

  // Cursor / drawing mode switches
  static const modeArrow = 'MODE_ARROW';
  static const modeLaser = 'MODE_LASER';
  static const modePen = 'MODE_PEN';
  static const modeHighlighter = 'MODE_HIGHLIGHTER';
  static const modeEraser = 'MODE_ERASER';


  // Mouse actions
  static const leftClick = 'LEFT_CLICK';
  static const rightClick = 'RIGHT_CLICK';
  static const leftDown = 'LEFT_DOWN';
  static const leftUp = 'LEFT_UP';

  // Laser lifecycle
  static const laserOff = 'LASER_OFF';

  // Legacy alias kept for backwards‑compat (maps to modeLaser on PC)
  static const laserCursor = 'LASER_CURSOR';

  // ── High‑frequency message types ──
  static const typeLaser = 'LASER';
  static const typeTouch = 'TOUCH';
  static const typeScroll = 'SCROLL';

  static const allowedCommands = <String>{
    next, prev, start, end, lock, clearInk,
    modeArrow, modeLaser, modePen, modeHighlighter, modeEraser,
    leftClick, rightClick, leftDown, leftUp,
    laserOff, laserCursor,
  };

  /// All message‑type values the PC server will accept.
  static const allowedTypes = <String>{
    typeLaser, typeTouch, typeScroll,
  };
}
