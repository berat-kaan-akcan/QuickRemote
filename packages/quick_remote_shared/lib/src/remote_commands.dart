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

  /// The screen darkened but for a circle that follows the laser's motion
  /// (LASER frames); LASER_OFF or MODE_ARROW ends it. Only QuickRemote's
  /// overlay draws it: sent only to a PC whose auth reply has `overlay`.
  static const modeSpotlight = 'MODE_SPOTLIGHT';

  /// A round magnifier that follows the laser's motion, as the spotlight;
  /// sent only to a PC whose auth reply has `zoom` (Windows).
  static const modeZoom = 'MODE_ZOOM';

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

  /// Takes back the last stroke the overlay drew (`overlay` PCs only).
  static const undoInk = 'UNDO_INK';

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

  static const allowedCommands = <String>{
    next, prev, start, end, lock, refreshState,
    modeArrow, modeLaser, modePen, modeHighlighter, modeEraser, modeSpotlight, modeZoom,
    leftClick, rightClick, leftDown, leftUp,
    laserOff, laserCursor, blackScreen, whiteScreen, eraseAll, undoInk,
    // Medya & ses
    mediaPlayPause, mediaRewind,
    volumeUp, volumeDown, volumeMute,
    sysMediaPlayPause, sysMediaNext, sysMediaPrev, sysMediaStop,
  };

  /// Parametreli komutların prefix'leri (ör: SET_PEN_COLOR:123, START_AT:5).
  static const allowedPrefixes = <String>{
    'SET_PEN_COLOR',
    'SET_HIGHLIGHTER_COLOR',
    'START_AT',
    'VOLUME_SET',
    'SET_KEEP_INK',
    'SLIDE_PREVIEW',
    'SLIDE_THUMB',
  };

  // Parameterized commands; the PC validates the range of each value.
  static String startAt(int slide) => 'START_AT:$slide';
  static String penColor(int bgr) => 'SET_PEN_COLOR:$bgr';
  static String highlighterColor(int bgr) => 'SET_HIGHLIGHTER_COLOR:$bgr';
  static String volumeSet(int level) => 'VOLUME_SET:$level';

  /// The phone's "keep the ink on slide change" setting, sent after every
  /// connect and on change. The PC keeps it per phone, in memory only: the
  /// phone that sends NEXT, PREV or START_AT decides whether the ink stays.
  static String keepInk(bool keep) => 'SET_KEEP_INK:${keep ? 1 : 0}';

  /// Turns the slide images (binary [SlideImageFrame]s) on or off for this
  /// phone, sent after every connect and on change. The PC never sends a
  /// binary frame to a phone that did not turn them on: older phones read
  /// every frame as text.
  static String slidePreview(bool on) => 'SLIDE_PREVIEW:${on ? 1 : 0}';

  /// Asks for the thumbnail of slide [slide] (from 1), for the slide list.
  static String slideThumb(int slide) => 'SLIDE_THUMB:$slide';
}

