import 'package:flutter/foundation.dart';
import 'package:screen_retriever/screen_retriever.dart';
import '../../mouse_controller.dart';
import 'uinput_device.dart';

/// Moves the cursor through the uinput virtual mouse (relative motion), so it
/// works on X11 and Wayland alike. Wayland does not let clients read or warp
/// the global cursor, so the position is tracked virtually from the deltas.
class LinuxMouseController implements MouseController {
  final UinputDevice _device = UinputDevice.instance;
  double _currentX = 0;
  double _currentY = 0;
  int _screenWidth = 1920;
  int _screenHeight = 1080;
  bool _initialized = false;

  // Sub-pixel remainders: relative events are integers, so slow touchpad
  // motion would otherwise be truncated to zero.
  double _remX = 0;
  double _remY = 0;

  @override
  void init() {
    _initialized = true;
    _currentX = _screenWidth / 2;
    _currentY = _screenHeight / 2;
    _device.ensureOpen();
    _loadScreenSize();
  }

  Future<void> _loadScreenSize() async {
    try {
      final display = await screenRetriever.getPrimaryDisplay();
      _screenWidth = display.size.width.round();
      _screenHeight = display.size.height.round();
      _currentX = _screenWidth / 2;
      _currentY = _screenHeight / 2;
    } catch (e) {
      debugPrint('LinuxMouseController: screen size unavailable, using default: $e');
    }
  }

  @override
  int get screenWidth => _screenWidth;
  @override
  int get screenHeight => _screenHeight;
  @override
  double get currentX => _currentX;
  @override
  double get currentY => _currentY;

  @override
  void trackDelta(double dx, double dy) {
    if (!_initialized) init();
    _currentX = (_currentX + dx).clamp(0, _screenWidth.toDouble() - 1);
    _currentY = (_currentY + dy).clamp(0, _screenHeight.toDouble() - 1);
  }

  @override
  void moveDelta(double dx, double dy) {
    trackDelta(dx, dy);
    _remX += dx;
    _remY += dy;
    final ix = _remX.truncate();
    final iy = _remY.truncate();
    _remX -= ix;
    _remY -= iy;
    if (ix != 0 || iy != 0) _device.moveRelative(ix, iy);
  }

  // Absolute warping is impossible with a relative device on Wayland; move by
  // the difference from the tracked position instead.
  @override
  void moveTo(double x, double y) {
    if (!_initialized) init();
    moveDelta(x - _currentX, y - _currentY);
  }

  @override
  void resetToCenter() => moveTo(_screenWidth / 2, _screenHeight / 2);
}
