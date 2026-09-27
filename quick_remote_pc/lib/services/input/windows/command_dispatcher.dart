import 'package:flutter/foundation.dart';
import 'package:win32/win32.dart';
import 'keyboard_simulator.dart';
import 'mouse_simulator.dart';
import 'ppt_controller.dart';
import 'volume_controller.dart';

class CommandDispatcher {
  static void executeCommand(String command) {
    if (command.startsWith('SET_PEN_COLOR:')) {
      final bgrStr = command.split(':')[1];
      final bgr = int.tryParse(bgrStr);
      if (bgr != null && bgr >= 0 && bgr <= 16777215) {
        PptController.setPenColor(bgr);
      } else {
        debugPrint('Invalid BGR color value: $bgrStr (must be 0-16777215)');
      }
      return;
    }

    if (command.startsWith('START_AT:')) {
      final slideStr = command.split(':')[1];
      final slideNumber = int.tryParse(slideStr);
      if (slideNumber != null) {
        PptController.slideStartAt(slideNumber);
      }
      return;
    }

    if (command.startsWith('VOLUME_SET:')) {
      final levelStr = command.split(':')[1];
      final level = int.tryParse(levelStr);
      if (level != null && level >= 0 && level <= 100) {
        VolumeController.setVolume(level);
      } else {
        debugPrint('Invalid VOLUME_SET value: $levelStr (must be 0-100)');
      }
      return;
    }

    switch (command) {
      case 'NEXT':
        PptController.slideNext();
        break;
      case 'PREV':
        PptController.slidePrev();
        break;
      case 'START':
        PptController.slideStart();
        break;
      case 'END':
        PptController.slideEnd();
        break;
      case 'BLACK_SCREEN':
        PptController.blackScreen();
        break;
      case 'WHITE_SCREEN':
        PptController.whiteScreen();
        break;
      case 'ERASE_ALL':
        PptController.eraseAllInk();
        break;

      case 'LOCK':
        LockWorkStation(); // from win32
        break;
      case 'LASER_CURSOR':
        PptController.toggleLaserCursor();
        break;
      case 'MODE_ARROW':
        KeyboardSimulator.pressKeyCombo([VK_CONTROL, 0x41]); // Ctrl + A
        PptController.setLaserActive(false);
        break;
      case 'MODE_LASER':
        KeyboardSimulator.pressKeyCombo([VK_CONTROL, 0x4C]); // Ctrl + L
        PptController.setLaserActive(true);
        break;
      case 'MODE_PEN':
        KeyboardSimulator.pressKeyCombo([VK_CONTROL, 0x50]); // Ctrl + P
        PptController.setLaserActive(false);
        break;
      case 'MODE_HIGHLIGHTER':
        KeyboardSimulator.pressKeyCombo([VK_CONTROL, 0x49]); // Ctrl + I
        PptController.setLaserActive(false);
        break;
      case 'MODE_ERASER':
        KeyboardSimulator.pressKeyCombo([VK_CONTROL, 0x45]); // Ctrl + E
        PptController.setLaserActive(false);
        break;
      case 'LEFT_CLICK':
        MouseSimulator.leftClick();
        break;
      case 'RIGHT_CLICK':
        MouseSimulator.rightClick();
        break;
      case 'LEFT_DOWN':
        MouseSimulator.leftDown();
        break;
      case 'LEFT_UP':
        MouseSimulator.leftUp();
        break;
      case 'LASER_OFF':
        KeyboardSimulator.pressKeyCombo([VK_CONTROL, 0x41]); // Ctrl + A
        PptController.setLaserActive(false);
        break;

      // ── Ses kontrolü ──
      case 'VOLUME_UP':
        VolumeController.volumeUp();
        break;
      case 'VOLUME_DOWN':
        VolumeController.volumeDown();
        break;
      case 'VOLUME_MUTE':
        VolumeController.volumeMute();
        break;

      // ── PPT gömülü video ──
      case 'MEDIA_PLAY_PAUSE':
        PptController.pptMediaPlayPause();
        break;
      case 'MEDIA_REWIND':
        PptController.pptMediaRewind();
        break;

      // ── Sistem medya transport ──
      case 'SYSTEM_MEDIA_PLAY_PAUSE':
        KeyboardSimulator.pressKey(0xB3); // VK_MEDIA_PLAY_PAUSE
        break;
      case 'SYSTEM_MEDIA_NEXT':
        KeyboardSimulator.pressKey(0xB0); // VK_MEDIA_NEXT_TRACK
        break;
      case 'SYSTEM_MEDIA_PREV':
        KeyboardSimulator.pressKey(0xB1); // VK_MEDIA_PREV_TRACK
        break;
      case 'SYSTEM_MEDIA_STOP':
        KeyboardSimulator.pressKey(0xB2); // VK_MEDIA_STOP
        break;

      default:
        debugPrint('Unknown command: $command');
    }
  }
}
