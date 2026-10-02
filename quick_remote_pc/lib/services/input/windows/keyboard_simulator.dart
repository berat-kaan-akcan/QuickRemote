import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

class KeyboardSimulator {
  /// Keys that need KEYEVENTF_EXTENDEDKEY: media keys, navigation block, arrows.
  static bool _isExtended(int vk) =>
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

  /// Simulate a single key press (down + up).
  static void pressKey(int vkCode) => pressKeyCombo([vkCode]);

  /// Simulate a key combination (e.g., Win+L): all keys down, then up in
  /// reverse order, in one SendInput call.
  static void pressKeyCombo(List<int> vkCodes) {
    final count = vkCodes.length * 2;
    final inputs = calloc<INPUT>(count);

    void set(int index, int vk, {required bool up}) {
      final ext = _isExtended(vk) ? 0x0001 : 0; // KEYEVENTF_EXTENDEDKEY
      inputs[index].type = INPUT_KEYBOARD;
      inputs[index].ki.wVk = VIRTUAL_KEY(vk);
      inputs[index].ki.dwFlags = KEYBD_EVENT_FLAGS((up ? KEYEVENTF_KEYUP : 0) | ext);
    }

    for (var i = 0; i < vkCodes.length; i++) {
      set(i, vkCodes[i], up: false);
      set(vkCodes.length + i, vkCodes[vkCodes.length - 1 - i], up: true);
    }

    SendInput(count, inputs, sizeOf<INPUT>());
    calloc.free(inputs);
  }
}
