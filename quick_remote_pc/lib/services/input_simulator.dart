import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:win32/win32.dart';

/// Windows input simulator using Win32 SendInput API.
/// Simulates keyboard key presses and system commands.
class InputSimulator {
  /// Simulate a single key press (down + up).
  static void pressKey(int vkCode) {
    final inputs = calloc<INPUT>(2);

    // Key down
    inputs[0].type = INPUT_KEYBOARD;
    inputs[0].ki.wVk = VIRTUAL_KEY(vkCode);
    inputs[0].ki.dwFlags = KEYBD_EVENT_FLAGS(0);

    // Key up
    inputs[1].type = INPUT_KEYBOARD;
    inputs[1].ki.wVk = VIRTUAL_KEY(vkCode);
    inputs[1].ki.dwFlags = KEYEVENTF_KEYUP;

    SendInput(2, inputs, sizeOf<INPUT>());
    calloc.free(inputs);
  }

  /// Simulate a key combination (e.g., Win+L).
  static void pressKeyCombo(List<int> vkCodes) {
    final count = vkCodes.length * 2;
    final inputs = calloc<INPUT>(count);

    // All keys down
    for (var i = 0; i < vkCodes.length; i++) {
      inputs[i].type = INPUT_KEYBOARD;
      inputs[i].ki.wVk = VIRTUAL_KEY(vkCodes[i]);
      inputs[i].ki.dwFlags = KEYBD_EVENT_FLAGS(0);
    }

    // All keys up (reverse order)
    for (var i = 0; i < vkCodes.length; i++) {
      final idx = vkCodes.length + i;
      inputs[idx].type = INPUT_KEYBOARD;
      inputs[idx].ki.wVk = VIRTUAL_KEY(vkCodes[vkCodes.length - 1 - i]);
      inputs[idx].ki.dwFlags = KEYEVENTF_KEYUP;
    }

    SendInput(count, inputs, sizeOf<INPUT>());
    calloc.free(inputs);
  }

  // --- Command handlers ---

  /// Slide next (Right arrow)
  static void slideNext() => pressKey(VK_RIGHT);

  /// Slide previous (Left arrow)
  static void slidePrev() => pressKey(VK_LEFT);

  /// Start presentation (F5)
  static void slideStart() => pressKey(VK_F5);

  /// End presentation (Escape)
  static void slideEnd() => pressKey(VK_ESCAPE);

  /// Lock workstation
  static void lockPC() => LockWorkStation();

  static bool _isLaserActive = false;

  /// Toggle PowerPoint laser pointer using keyboard shortcuts (Ctrl+L / Ctrl+A)
  static void toggleLaserCursor() {
    if (_isLaserActive) {
      // Turn laser off (Ctrl + A for Arrow in PowerPoint)
      pressKeyCombo([VK_CONTROL, 0x41]); // 0x41 is 'A'
      _isLaserActive = false;
    } else {
      // Turn laser on (Ctrl + L for Laser in PowerPoint)
      pressKeyCombo([VK_CONTROL, 0x4C]); // 0x4C is 'L'
      _isLaserActive = true;
    }
  }

  /// Simulate left mouse click
  static void leftClick() {
    final inputs = calloc<INPUT>(2);

    // Mouse type = INPUT_TYPE(0)
    inputs[0].type = const INPUT_TYPE(0);
    inputs[0].mi.dwFlags = MOUSEEVENTF_LEFTDOWN;

    inputs[1].type = const INPUT_TYPE(0);
    inputs[1].mi.dwFlags = MOUSEEVENTF_LEFTUP;

    SendInput(2, inputs, sizeOf<INPUT>());
    calloc.free(inputs);
  }

  /// Execute a command string from the client.
  static void executeCommand(String command) {
    switch (command) {
      case 'NEXT':
        slideNext();
        break;
      case 'PREV':
        slidePrev();
        break;
      case 'START':
        slideStart();
        break;
      case 'END':
        slideEnd();
        break;
      case 'LOCK':
        lockPC();
        break;
      case 'LASER_CURSOR':
        toggleLaserCursor();
        break;
      case 'LEFT_CLICK':
        leftClick();
        break;
      default:
        debugPrint('Unknown command: $command');
    }
  }
}
