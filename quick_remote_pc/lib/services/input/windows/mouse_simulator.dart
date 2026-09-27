import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

class MouseSimulator {
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
}
