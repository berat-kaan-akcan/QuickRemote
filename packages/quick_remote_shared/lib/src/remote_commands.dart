/// Centralized command and message type constants shared between
/// the mobile app and the PC companion.
abstract class RemoteCommands {
  // Slide / presentation controls
  static const next = 'NEXT';
  static const prev = 'PREV';
  static const start = 'START';
  static const end = 'END';
  static const lock = 'LOCK';
  static const refreshState = 'REFRESH_STATE';

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

  // Screen controls
  static const blackScreen = 'BLACK_SCREEN';
  static const whiteScreen = 'WHITE_SCREEN';
  static const eraseAll = 'ERASE_ALL';

  // Legacy alias kept for backwards‑compat (maps to modeLaser on PC)
  static const laserCursor = 'LASER_CURSOR';

  // PPT gömülü video kontrolü
  static const mediaPlayPause = 'MEDIA_PLAY_PAUSE';
  static const mediaRewind    = 'MEDIA_REWIND';

  // Sistem ses kontrolü
  static const volumeUp   = 'VOLUME_UP';
  static const volumeDown = 'VOLUME_DOWN';
  static const volumeMute = 'VOLUME_MUTE';

  // Sistem medya transport (Spotify, YouTube vb.)
  static const sysMediaPlayPause = 'SYSTEM_MEDIA_PLAY_PAUSE';
  static const sysMediaNext      = 'SYSTEM_MEDIA_NEXT';
  static const sysMediaPrev      = 'SYSTEM_MEDIA_PREV';
  static const sysMediaStop      = 'SYSTEM_MEDIA_STOP';

  // ── High‑frequency message types ──
  static const typeLaser = 'LASER';
  static const typeTouch = 'TOUCH';

  static const allowedCommands = <String>{
    next, prev, start, end, lock, refreshState,
    modeArrow, modeLaser, modePen, modeHighlighter, modeEraser,
    leftClick, rightClick, leftDown, leftUp,
    laserOff, laserCursor, blackScreen, whiteScreen, eraseAll,
    // Medya & ses
    mediaPlayPause, mediaRewind,
    volumeUp, volumeDown, volumeMute,
    sysMediaPlayPause, sysMediaNext, sysMediaPrev, sysMediaStop,
  };

  /// Parametreli komutların prefix'leri (ör: SET_PEN_COLOR:123, START_AT:5).
  static const allowedPrefixes = <String>{
    'SET_PEN_COLOR',
    'START_AT',
    'VOLUME_SET',
  };

  /// All message‑type values the PC server will accept.
  static const allowedTypes = <String>{
    typeLaser, typeTouch,
  };
}

