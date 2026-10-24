import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';
import '../../mouse_controller.dart';

/// Controls the mouse cursor on Windows through SendInput, across the whole
/// virtual desktop so a projector set up as a second monitor is reachable.
class WindowsMouseController implements MouseController {
  double _currentX = 0;
  double _currentY = 0;
  // Bounding box of all monitors; the primary monitor's top-left is 0,0, so
  // monitors left of or above it have negative coordinates.
  int _left = 0;
  int _top = 0;
  int _width = 1;
  int _height = 1;
  bool _initialized = false;
  DateTime _lastMove = DateTime.fromMillisecondsSinceEpoch(0);

  /// A pause longer than this starts a new gesture: the monitor layout and the
  /// real cursor position (the user may have moved the physical mouse) are
  /// read again, so the cursor continues from where it actually is.
  static const _gestureGap = Duration(milliseconds: 300);

  /// Initialize with the current monitor layout.
  @override
  void init() {
    _readBounds();
    // Start at the center of the primary monitor
    _currentX = GetSystemMetrics(SM_CXSCREEN) / 2;
    _currentY = GetSystemMetrics(SM_CYSCREEN) / 2;
    _initialized = true;
  }

  void _readBounds() {
    _left = GetSystemMetrics(SM_XVIRTUALSCREEN);
    _top = GetSystemMetrics(SM_YVIRTUALSCREEN);
    _width = GetSystemMetrics(SM_CXVIRTUALSCREEN).clamp(1, 1 << 20);
    _height = GetSystemMetrics(SM_CYVIRTUALSCREEN).clamp(1, 1 << 20);
  }

  void _syncWithSystemCursor() {
    final point = calloc<POINT>();
    try {
      if (GetCursorPos(point).value) {
        _currentX = point.ref.x.toDouble();
        _currentY = point.ref.y.toDouble();
      }
    } finally {
      calloc.free(point);
    }
  }

  void _startGestureIfIdle() {
    final now = DateTime.now();
    if (now.difference(_lastMove) > _gestureGap) {
      _readBounds();
      _syncWithSystemCursor();
    }
    _lastMove = now;
  }

  void _clamp() {
    _currentX = _currentX.clamp(_left.toDouble(), (_left + _width - 1).toDouble());
    _currentY = _currentY.clamp(_top.toDouble(), (_top + _height - 1).toDouble());
  }

  @override
  int get screenWidth => _width;
  @override
  int get screenHeight => _height;
  @override
  double get currentX => _currentX;
  @override
  double get currentY => _currentY;

  /// Move cursor by delta values (from touchpad/gyroscope).
  /// Uses SendInput instead of SetCursorPos to generate proper WM_MOUSEMOVE
  /// input events that applications like PowerPoint (pen/eraser mode) process.
  @override
  void moveDelta(double dx, double dy) {
    if (!_initialized) init();
    _startGestureIfIdle();

    _currentX += dx;
    _currentY += dy;
    _clamp();

    _send(_currentX, _currentY, _left, _top, _width, _height);
  }

  /// Moves the cursor to ([x], [y]), pixels of the virtual desktop (a point
  /// of a window's GetWindowRect), with the layout read now.
  static void moveTo(double x, double y) {
    final left = GetSystemMetrics(SM_XVIRTUALSCREEN);
    final top = GetSystemMetrics(SM_YVIRTUALSCREEN);
    final width = GetSystemMetrics(SM_CXVIRTUALSCREEN).clamp(1, 1 << 20);
    final height = GetSystemMetrics(SM_CYVIRTUALSCREEN).clamp(1, 1 << 20);
    _send(
      x.clamp(left.toDouble(), (left + width - 1).toDouble()),
      y.clamp(top.toDouble(), (top + height - 1).toDouble()),
      left,
      top,
      width,
      height,
    );
  }

  static void _send(double x, double y, int left, int top, int width, int height) {
    // Absolute coordinates on the virtual desktop are normalized to 0..65535.
    // SetCursorPos only moves the cursor without generating input messages,
    // which causes PowerPoint pen/eraser to not receive movement data.
    final normalX = ((x - left) * 65535 / (width > 1 ? width - 1 : 1)).round();
    final normalY = ((y - top) * 65535 / (height > 1 ? height - 1 : 1)).round();

    final inputs = calloc<INPUT>(1);
    inputs[0].type = const INPUT_TYPE(0); // INPUT_MOUSE
    inputs[0].mi.dx = normalX;
    inputs[0].mi.dy = normalY;
    inputs[0].mi.dwFlags = MOUSEEVENTF_MOVE | MOUSEEVENTF_ABSOLUTE | MOUSEEVENTF_VIRTUALDESK;
    SendInput(1, inputs, sizeOf<INPUT>());
    calloc.free(inputs);
  }

  @override
  void trackDelta(double dx, double dy) {
    if (!_initialized) init();
    _currentX += dx;
    _currentY += dy;
    _clamp();
  }
}
