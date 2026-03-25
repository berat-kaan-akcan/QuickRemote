import 'package:win32/win32.dart';

/// Controls the mouse cursor position on Windows using Win32 API.
class MouseController {
  double _currentX = 0;
  double _currentY = 0;
  late int _screenWidth;
  late int _screenHeight;
  bool _initialized = false;

  /// Initialize with current screen resolution.
  void init() {
    _screenWidth = GetSystemMetrics(SM_CXSCREEN);
    _screenHeight = GetSystemMetrics(SM_CYSCREEN);
    // Start at screen center
    _currentX = _screenWidth / 2;
    _currentY = _screenHeight / 2;
    _initialized = true;
  }

  int get screenWidth => _screenWidth;
  int get screenHeight => _screenHeight;
  double get currentX => _currentX;
  double get currentY => _currentY;

  /// Move cursor by delta values (from gyroscope).
  void moveDelta(double dx, double dy) {
    if (!_initialized) init();

    _currentX += dx;
    _currentY += dy;

    // Clamp to screen bounds
    _currentX = _currentX.clamp(0, _screenWidth.toDouble() - 1);
    _currentY = _currentY.clamp(0, _screenHeight.toDouble() - 1);

    SetCursorPos(_currentX.toInt(), _currentY.toInt());
  }

  /// Move cursor to absolute position.
  void moveTo(double x, double y) {
    if (!_initialized) init();

    _currentX = x.clamp(0, _screenWidth.toDouble() - 1);
    _currentY = y.clamp(0, _screenHeight.toDouble() - 1);

    SetCursorPos(_currentX.toInt(), _currentY.toInt());
  }

  /// Reset cursor to screen center.
  void resetToCenter() {
    if (!_initialized) init();

    _currentX = _screenWidth / 2;
    _currentY = _screenHeight / 2;
    SetCursorPos(_currentX.toInt(), _currentY.toInt());
  }
}
