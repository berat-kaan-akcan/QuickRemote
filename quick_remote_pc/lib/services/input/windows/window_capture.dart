import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:win32/win32.dart';

import '../input_service.dart' show ScreenCapture;

/// Takes a window's picture with `PrintWindow(PW_RENDERFULLCONTENT)`, which
/// also draws DirectX content and works while the window is behind another
/// one (Windows 8.1 and later). **Never run on Windows yet**: whether
/// PowerPoint's and WPS's shows and the browsers come out whole (not black)
/// is still to be tried.
class WindowCapture {
  WindowCapture._();

  /// PW_RENDERFULLCONTENT, missing from the win32 package's constants.
  static const _renderFullContent = PRINT_WINDOW_FLAGS(2);

  /// [hwnd]'s picture, its whole window rectangle; null when it cannot be had.
  static ScreenCapture? capture(HWND hwnd) {
    final rect = calloc<RECT>();
    final info = calloc<BITMAPINFO>();
    final bits = calloc<Pointer>();
    HDC? screenDc;
    HDC? memoryDc;
    HBITMAP? bitmap;
    HGDIOBJ? old;
    try {
      if (!GetWindowRect(hwnd, rect).value) return null;
      final width = rect.ref.right - rect.ref.left;
      final height = rect.ref.bottom - rect.ref.top;
      if (width <= 0 || height <= 0) return null;
      screenDc = GetDC(null);
      memoryDc = CreateCompatibleDC(screenDc);
      info.ref.bmiHeader
        ..biSize = sizeOf<BITMAPINFOHEADER>()
        ..biWidth = width
        ..biHeight =
            -height // top-down rows
        ..biPlanes = 1
        ..biBitCount = 32
        ..biCompression = BI_RGB;
      bitmap = CreateDIBSection(
        memoryDc,
        info,
        DIB_RGB_COLORS,
        bits,
        null,
        0,
      ).value;
      if (!bitmap.isValid || bits.value == nullptr) return null;
      old = SelectObject(memoryDc, HGDIOBJ(bitmap));
      if (!PrintWindow(hwnd, memoryDc, _renderFullContent)) return null;
      final pixels = Uint8List.fromList(
        bits.value.cast<Uint8>().asTypedList(width * height * 4),
      );
      // BGRA rows of width * 4 bytes: the layout ScreenCapture takes.
      return ScreenCapture(pixels: pixels, width: width, height: height);
    } catch (e) {
      debugPrint('WindowCapture failed: $e');
      return null;
    } finally {
      if (memoryDc != null && old != null) SelectObject(memoryDc, old);
      if (bitmap != null && bitmap.isValid) DeleteObject(HGDIOBJ(bitmap));
      if (memoryDc != null) DeleteDC(memoryDc);
      if (screenDc != null) ReleaseDC(null, screenDc);
      calloc.free(bits);
      calloc.free(info);
      calloc.free(rect);
    }
  }

  /// Whether [hwnd] covers its whole monitor: a viewer or browser in full
  /// screen, the only kind whose picture goes to a phone.
  static bool coversMonitor(HWND hwnd) {
    final rect = calloc<RECT>();
    final monitor = calloc<MONITORINFO>()..ref.cbSize = sizeOf<MONITORINFO>();
    try {
      if (!GetWindowRect(hwnd, rect).value) return false;
      final screen = MonitorFromWindow(hwnd, MONITOR_DEFAULTTONEAREST);
      if (!GetMonitorInfo(screen, monitor)) return false;
      final m = monitor.ref.rcMonitor;
      final r = rect.ref;
      return r.left <= m.left &&
          r.top <= m.top &&
          r.right >= m.right &&
          r.bottom >= m.bottom;
    } finally {
      calloc.free(monitor);
      calloc.free(rect);
    }
  }
}
