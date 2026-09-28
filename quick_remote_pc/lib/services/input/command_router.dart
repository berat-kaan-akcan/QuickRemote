import 'package:flutter/foundation.dart';
import 'input_service.dart';

/// Parses a validated remote command string and routes it to the platform
/// [InputService]. Shared by every platform so parameter parsing and
/// validation behave identically everywhere.
class CommandRouter {
  static void execute(InputService service, String command) {
    if (command.startsWith('SET_PEN_COLOR:')) {
      final bgr = parseIntArg(command, min: 0, max: 0xFFFFFF);
      if (bgr != null) {
        service.setPenColor(bgr);
      } else {
        debugPrint('Invalid BGR color value in $command (must be 0-16777215)');
      }
      return;
    }

    if (command.startsWith('START_AT:')) {
      final slideNumber = parseIntArg(command, min: 1);
      if (slideNumber != null) {
        service.slideStartAt(slideNumber);
      }
      return;
    }

    if (command.startsWith('VOLUME_SET:')) {
      final level = parseIntArg(command, min: 0, max: 100);
      if (level != null) {
        service.setVolume(level);
      } else {
        debugPrint('Invalid VOLUME_SET value in $command (must be 0-100)');
      }
      return;
    }

    switch (command) {
      case 'NEXT':
        service.slideNext();
      case 'PREV':
        service.slidePrev();
      case 'START':
        service.slideStart();
      case 'END':
        service.slideEnd();
      case 'BLACK_SCREEN':
        service.blackScreen();
      case 'WHITE_SCREEN':
        service.whiteScreen();
      case 'ERASE_ALL':
        service.eraseAllInk();
      case 'LOCK':
        service.lockPC();

      // ── Çizim / imleç modları ──
      case 'LASER_CURSOR':
        service.toggleLaserCursor();
      case 'MODE_ARROW':
        service.modeArrow();
      case 'MODE_LASER':
        service.modeLaser();
      case 'MODE_PEN':
        service.modePen();
      case 'MODE_HIGHLIGHTER':
        service.modeHighlighter();
      case 'MODE_ERASER':
        service.modeEraser();
      case 'LASER_OFF':
        service.laserOff();

      // ── Fare ──
      case 'LEFT_CLICK':
        service.leftClick();
      case 'RIGHT_CLICK':
        service.rightClick();
      case 'LEFT_DOWN':
        service.leftDown();
      case 'LEFT_UP':
        service.leftUp();

      // ── Ses kontrolü ──
      case 'VOLUME_UP':
        service.volumeUp();
      case 'VOLUME_DOWN':
        service.volumeDown();
      case 'VOLUME_MUTE':
        service.volumeMute();

      // ── Sunum gömülü video ──
      case 'MEDIA_PLAY_PAUSE':
        service.pptMediaPlayPause();
      case 'MEDIA_REWIND':
        service.pptMediaRewind();

      // ── Sistem medya transport ──
      case 'SYSTEM_MEDIA_PLAY_PAUSE':
        service.sysMediaPlayPause();
      case 'SYSTEM_MEDIA_NEXT':
        service.sysMediaNext();
      case 'SYSTEM_MEDIA_PREV':
        service.sysMediaPrev();
      case 'SYSTEM_MEDIA_STOP':
        service.sysMediaStop();

      default:
        debugPrint('Unknown command: $command');
    }
  }

  /// Parses the integer after the first ':' of a `PREFIX:value` command.
  /// Returns null when missing, non-numeric or outside [min]..[max].
  @visibleForTesting
  static int? parseIntArg(String command, {int? min, int? max}) {
    final idx = command.indexOf(':');
    if (idx < 0) return null;
    final value = int.tryParse(command.substring(idx + 1));
    if (value == null) return null;
    if (min != null && value < min) return null;
    if (max != null && value > max) return null;
    return value;
  }
}
