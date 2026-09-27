import 'dart:io';
import '../../mouse_controller.dart';

class LinuxMouseController implements MouseController {
  double _currentX = 0;
  double _currentY = 0;
  int _screenWidth = 1920;
  int _screenHeight = 1080;
  bool _initialized = false;

  @override
  void init() {
    try {
      final result = Process.runSync('xdotool', ['getdisplaygeometry']);
      if (result.exitCode == 0) {
        final parts = result.stdout.toString().trim().split(' ');
        if (parts.length == 2) {
          _screenWidth = int.tryParse(parts[0]) ?? 1920;
          _screenHeight = int.tryParse(parts[1]) ?? 1080;
        }
      }
    } catch (e) {
      print('xdotool not installed or failed: $e');
    }
    _currentX = _screenWidth / 2;
    _currentY = _screenHeight / 2;
    _initialized = true;
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
  void moveDelta(double dx, double dy) {
    if (!_initialized) init();
    _currentX += dx;
    _currentY += dy;
    
    _currentX = _currentX.clamp(0, _screenWidth.toDouble() - 1);
    _currentY = _currentY.clamp(0, _screenHeight.toDouble() - 1);

    _runXdoTool(['mousemove_relative', '--', dx.toInt().toString(), dy.toInt().toString()]);
  }

  @override
  void moveTo(double x, double y) {
    if (!_initialized) init();
    _currentX = x.clamp(0, _screenWidth.toDouble() - 1);
    _currentY = y.clamp(0, _screenHeight.toDouble() - 1);

    _runXdoTool(['mousemove', _currentX.toInt().toString(), _currentY.toInt().toString()]);
  }

  @override
  void resetToCenter() {
    if (!_initialized) init();
    _currentX = _screenWidth / 2;
    _currentY = _screenHeight / 2;
    _runXdoTool(['mousemove', _currentX.toInt().toString(), _currentY.toInt().toString()]);
  }

  void _runXdoTool(List<String> args) {
    try {
      Process.run('xdotool', args);
    } catch (e) {
      print('Failed to run xdotool: $e');
    }
  }
}
