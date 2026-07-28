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

  /// Clear ink drawings on current slide (E key)
  static void clearInk() => pressKey(0x45); // 'E' key is 0x45

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
    inputs[0].type = const INPUT_TYPE(0);
    inputs[0].mi.dwFlags = MOUSEEVENTF_LEFTDOWN;
    inputs[1].type = const INPUT_TYPE(0);
    inputs[1].mi.dwFlags = MOUSEEVENTF_LEFTUP;
    SendInput(2, inputs, sizeOf<INPUT>());
    calloc.free(inputs);
  }

  /// Simulate right mouse click
  static void rightClick() {
    final inputs = calloc<INPUT>(2);
    inputs[0].type = const INPUT_TYPE(0);
    inputs[0].mi.dwFlags = MOUSEEVENTF_RIGHTDOWN;
    inputs[1].type = const INPUT_TYPE(0);
    inputs[1].mi.dwFlags = MOUSEEVENTF_RIGHTUP;
    SendInput(2, inputs, sizeOf<INPUT>());
    calloc.free(inputs);
  }

  /// Left mouse button down
  static void leftDown() {
    final inputs = calloc<INPUT>(1);
    inputs[0].type = const INPUT_TYPE(0);
    inputs[0].mi.dwFlags = MOUSEEVENTF_LEFTDOWN;
    SendInput(1, inputs, sizeOf<INPUT>());
    calloc.free(inputs);
  }

  /// Left mouse button up
  static void leftUp() {
    final inputs = calloc<INPUT>(1);
    inputs[0].type = const INPUT_TYPE(0);
    inputs[0].mi.dwFlags = MOUSEEVENTF_LEFTUP;
    SendInput(1, inputs, sizeOf<INPUT>());
    calloc.free(inputs);
  }

  /// Simulate mouse scroll
  static void scroll(double dy) {
    // Win32 MOUSEEVENTF_WHEEL takes mouseData as amount of wheel movement.
    // Positive value means wheel rotated forward (away from user, scrolling up)
    // Negative value means wheel rotated backward (toward user, scrolling down)
    // We get 'dy' from mobile which is delta movement of finger.
    // Negative dy = finger goes up = scroll down = negative mouseData
    final inputs = calloc<INPUT>(1);
    inputs[0].type = const INPUT_TYPE(0);
    inputs[0].mi.dwFlags = MOUSEEVENTF_WHEEL;
    inputs[0].mi.mouseData = (-dy * 2).round(); // Negate: finger down = scroll down
    SendInput(1, inputs, sizeOf<INPUT>());
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
      case 'CLEAR_INK':
        clearInk();
        break;
      case 'LOCK':
        lockPC();
        break;
      case 'LASER_CURSOR':
        toggleLaserCursor();
        break;
      case 'MODE_ARROW':
        pressKeyCombo([VK_CONTROL, 0x41]); // Ctrl + A
        _isLaserActive = false;
        break;
      case 'MODE_LASER':
        // PowerPoint'in kendi lazer işaretçisini aç (Ctrl + L)
        pressKeyCombo([VK_CONTROL, 0x4C]); // Ctrl + L
        _isLaserActive = true;
        break;
      case 'MODE_PEN':
        pressKeyCombo([VK_CONTROL, 0x50]); // Ctrl + P
        _isLaserActive = false;
        break;
      case 'MODE_ERASER':
        pressKeyCombo([VK_CONTROL, 0x45]); // Ctrl + E
        _isLaserActive = false;
        break;
      case 'LEFT_CLICK':
        leftClick();
        break;
      case 'RIGHT_CLICK':
        rightClick();
        break;
      case 'LEFT_DOWN':
        leftDown();
        break;
      case 'LEFT_UP':
        leftUp();
        break;
      case 'LASER_OFF':
        // PowerPoint'te lazeri kapatmak için normal Ok moduna dön (Ctrl + A)
        pressKeyCombo([VK_CONTROL, 0x41]); // Ctrl + A
        _isLaserActive = false;
        break;
      default:
        debugPrint('Unknown command: $command');
    }
  }
}
