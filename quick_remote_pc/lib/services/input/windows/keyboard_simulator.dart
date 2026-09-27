import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

class KeyboardSimulator {
  /// Simulate a single key press (down + up).
  static void pressKey(int vkCode) {
    final inputs = calloc<INPUT>(2);

    final isExtended =
        (vkCode >= 0xAE && vkCode <= 0xB3) ||
        vkCode == VK_NEXT ||
        vkCode == VK_PRIOR ||
        vkCode == VK_HOME ||
        vkCode == VK_END ||
        vkCode == VK_LEFT ||
        vkCode == VK_UP ||
        vkCode == VK_RIGHT ||
        vkCode == VK_DOWN ||
        vkCode == VK_INSERT ||
        vkCode == VK_DELETE;
    final int extFlag = isExtended
        ? 0x0001
        : 0; // KEYEVENTF_EXTENDEDKEY = 0x0001

    // Key down
    inputs[0].type = INPUT_KEYBOARD;
    inputs[0].ki.wVk = VIRTUAL_KEY(vkCode);
    inputs[0].ki.dwFlags = KEYBD_EVENT_FLAGS(extFlag);

    // Key up
    inputs[1].type = INPUT_KEYBOARD;
    inputs[1].ki.wVk = VIRTUAL_KEY(vkCode);
    inputs[1].ki.dwFlags = KEYBD_EVENT_FLAGS(KEYEVENTF_KEYUP | extFlag);

    SendInput(2, inputs, sizeOf<INPUT>());
    calloc.free(inputs);
  }

  /// Simulate a key combination (e.g., Win+L).
  static void pressKeyCombo(List<int> vkCodes) {
    final count = vkCodes.length * 2;
    final inputs = calloc<INPUT>(count);

    // All keys down
    for (var i = 0; i < vkCodes.length; i++) {
      final vk = vkCodes[i];
      final isExtended =
          (vk >= 0xAE && vk <= 0xB3) ||
          vk == VK_NEXT ||
          vk == VK_PRIOR ||
          vk == VK_HOME ||
          vk == VK_END ||
          vk == VK_LEFT ||
          vk == VK_UP ||
          vk == VK_RIGHT ||
          vk == VK_DOWN ||
          vk == VK_INSERT ||
          vk == VK_DELETE;
      final int extFlag = isExtended ? 0x0001 : 0;

      inputs[i].type = INPUT_KEYBOARD;
      inputs[i].ki.wVk = VIRTUAL_KEY(vk);
      inputs[i].ki.dwFlags = KEYBD_EVENT_FLAGS(extFlag);
    }

    // All keys up (reverse order)
    for (var i = 0; i < vkCodes.length; i++) {
      final idx = vkCodes.length + i;
      final vk = vkCodes[vkCodes.length - 1 - i];
      final isExtended =
          (vk >= 0xAE && vk <= 0xB3) ||
          vk == VK_NEXT ||
          vk == VK_PRIOR ||
          vk == VK_HOME ||
          vk == VK_END ||
          vk == VK_LEFT ||
          vk == VK_UP ||
          vk == VK_RIGHT ||
          vk == VK_DOWN ||
          vk == VK_INSERT ||
          vk == VK_DELETE;
      final int extFlag = isExtended ? 0x0001 : 0;

      inputs[idx].type = INPUT_KEYBOARD;
      inputs[idx].ki.wVk = VIRTUAL_KEY(vk);
      inputs[idx].ki.dwFlags = KEYBD_EVENT_FLAGS(KEYEVENTF_KEYUP | extFlag);
    }

    SendInput(count, inputs, sizeOf<INPUT>());
    calloc.free(inputs);
  }
}
