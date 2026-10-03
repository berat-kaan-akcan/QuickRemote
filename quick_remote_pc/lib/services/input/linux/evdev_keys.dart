/// Linux evdev codes (linux/input-event-codes.h) and the Windows
/// virtual-key → evdev mapping, so callers can keep using VK codes.
abstract class Evdev {
  // Event types
  static const evSyn = 0x00;
  static const evKey = 0x01;
  static const evRel = 0x02;
  static const evAbs = 0x03;
  static const synReport = 0;
  static const relX = 0x00;
  static const relY = 0x01;
  static const absX = 0x00;
  static const absY = 0x01;

  // Mouse buttons
  static const btnLeft = 0x110;
  static const btnRight = 0x111;
  static const btnMiddle = 0x112;

  // Keys used directly by the Linux input service
  static const keyEsc = 1;
  static const keyEnter = 28;
  static const keyLeftCtrl = 29;
  static const keyLeftAlt = 56;
  static const keyLeftMeta = 125;
  static const keyB = 48;
  static const keyW = 17;
  static const keyE = 18;
  static const keyL = 38;
  static const keyF5 = 63;
  static const keyPageUp = 104;
  static const keyPageDown = 109;
  static const keyMute = 113;
  static const keyVolumeDown = 114;
  static const keyVolumeUp = 115;
  static const keyNextSong = 163;
  static const keyPlayPause = 164;
  static const keyPreviousSong = 165;
  static const keyStopCd = 166;

  // Letter keys in A..Z order (QWERTY positions).
  static const _letters = [
    30, 48, 46, 32, 18, 33, 34, 35, 23, 36, 37, 38, 50, //
    49, 24, 25, 16, 19, 31, 20, 22, 47, 17, 45, 21, 44,
  ];

  static const _vkMap = <int, int>{
    0x08: 14, // Backspace
    0x09: 15, // Tab
    0x0D: keyEnter,
    0x10: 42, // Shift
    0x11: keyLeftCtrl,
    0x12: keyLeftAlt,
    0x1B: keyEsc,
    0x20: 57, // Space
    0x21: keyPageUp,
    0x22: keyPageDown,
    0x23: 107, // End
    0x24: 102, // Home
    0x25: 105, // Left
    0x26: 103, // Up
    0x27: 106, // Right
    0x28: 108, // Down
    0x2D: 110, // Insert
    0x2E: 111, // Delete
    0x5B: keyLeftMeta, // Windows key
    0xA0: 42, // Left Shift
    0xA2: keyLeftCtrl,
    0xA4: keyLeftAlt,
    0xAD: keyMute,
    0xAE: keyVolumeDown,
    0xAF: keyVolumeUp,
    0xB0: keyNextSong,
    0xB1: keyPreviousSong,
    0xB2: keyStopCd,
    0xB3: keyPlayPause,
  };

  /// Converts a Windows virtual-key code to an evdev key code, or null.
  static int? fromVk(int vk) {
    if (vk >= 0x41 && vk <= 0x5A) return _letters[vk - 0x41];
    if (vk == 0x30) return 11; // '0'
    if (vk >= 0x31 && vk <= 0x39) return vk - 0x31 + 2; // '1'..'9'
    if (vk >= 0x70 && vk <= 0x79) return 59 + (vk - 0x70); // F1..F10
    if (vk == 0x7A) return 87; // F11
    if (vk == 0x7B) return 88; // F12
    return _vkMap[vk];
  }

  /// Every key the virtual device may emit (registered at creation time).
  static Iterable<int> get allKeys sync* {
    yield* _letters;
    for (var k = 2; k <= 11; k++) {
      yield k; // digits
    }
    for (var k = 59; k <= 68; k++) {
      yield k; // F1..F10
    }
    yield 87;
    yield 88;
    yield* _vkMap.values.toSet();
    yield* const [btnLeft, btnRight, btnMiddle];
  }
}
