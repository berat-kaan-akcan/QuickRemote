import 'package:flutter/foundation.dart';
import 'package:quick_remote_shared/quick_remote_shared.dart';
import '../presenter_settings.dart';
import 'input_service.dart';

/// Parses a validated remote command string and routes it to the platform
/// [InputService]. Shared by every platform so parameter parsing and
/// validation behave identically everywhere.
class CommandRouter {
  static void execute(InputService service, String command) {
    final isPen = command.startsWith('SET_PEN_COLOR:');
    if (isPen || command.startsWith('SET_HIGHLIGHTER_COLOR:')) {
      final bgr = parseIntArg(command, min: 0, max: 0xFFFFFF);
      if (bgr == null) {
        debugPrint('Invalid BGR color value in $command (must be 0-16777215)');
      } else if (isPen) {
        service.setPenColor(bgr);
      } else {
        service.setHighlighterColor(bgr);
      }
      return;
    }

    if (command.startsWith('START_AT:')) {
      final slideNumber = parseIntArg(command, min: 1, max: 9999);
      if (slideNumber != null) {
        service.slideStartAt(slideNumber);
      }
      return;
    }

    if (command.startsWith('SET_KEEP_INK:')) {
      final keep = parseIntArg(command, min: 0, max: 1);
      if (keep != null) PresenterSettings.keepInkOnSlideChange = keep == 1;
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
      case RemoteCommands.next:
        service.slideNext();
      case RemoteCommands.prev:
        service.slidePrev();
      case RemoteCommands.start:
        service.slideStart();
      case RemoteCommands.end:
        service.slideEnd();
      case RemoteCommands.blackScreen:
        service.blackScreen();
      case RemoteCommands.whiteScreen:
        service.whiteScreen();
      case RemoteCommands.eraseAll:
        service.eraseAllInk();
      case RemoteCommands.lock:
        service.lockPC();

      // ── Çizim / imleç modları ──
      case RemoteCommands.laserCursor:
        service.toggleLaserCursor();
      case RemoteCommands.modeArrow:
        service.modeArrow();
      case RemoteCommands.modeLaser:
        service.modeLaser();
      case RemoteCommands.modePen:
        service.modePen();
      case RemoteCommands.modeHighlighter:
        service.modeHighlighter();
      case RemoteCommands.modeEraser:
        service.modeEraser();
      case RemoteCommands.laserOff:
        service.laserOff();

      // ── Fare ──
      case RemoteCommands.leftClick:
        service.leftClick();
      case RemoteCommands.rightClick:
        service.rightClick();
      case RemoteCommands.leftDown:
        service.leftDown();
      case RemoteCommands.leftUp:
        service.leftUp();

      // ── Ses kontrolü ──
      case RemoteCommands.volumeUp:
        service.volumeUp();
      case RemoteCommands.volumeDown:
        service.volumeDown();
      case RemoteCommands.volumeMute:
        service.volumeMute();

      // ── Sunum gömülü video ──
      case RemoteCommands.mediaPlayPause:
        service.pptMediaPlayPause();
      case RemoteCommands.mediaRewind:
        service.pptMediaRewind();

      // ── Sistem medya transport ──
      case RemoteCommands.sysMediaPlayPause:
        service.sysMediaPlayPause();
      case RemoteCommands.sysMediaNext:
        service.sysMediaNext();
      case RemoteCommands.sysMediaPrev:
        service.sysMediaPrev();
      case RemoteCommands.sysMediaStop:
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
