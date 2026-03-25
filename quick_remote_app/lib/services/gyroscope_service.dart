import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'websocket_service.dart';

/// Gyroscope service that reads phone rotation and sends delta positions
/// to PC for mouse cursor control (laser pointer mode).
class GyroscopeService extends ChangeNotifier {
  final WebSocketService _ws;
  StreamSubscription<GyroscopeEvent>? _subscription;
  bool _isActive = false;
  double _sensitivity = 8.0;

  bool get isActive => _isActive;
  double get sensitivity => _sensitivity;

  GyroscopeService(this._ws);

  /// Set sensitivity multiplier (1-20).
  void setSensitivity(double value) {
    _sensitivity = value.clamp(1.0, 20.0);
    notifyListeners();
  }

  /// Start sending gyroscope data.
  void start() {
    if (_isActive) return;
    _isActive = true;
    notifyListeners();

    // Notify PC to show laser overlay
    _ws.sendCommand('LASER_ON');

    _subscription = gyroscopeEventStream(
      samplingPeriod: const Duration(milliseconds: 30),
    ).listen((GyroscopeEvent event) {
      // event.y = rotation around Y axis (left/right tilt) → horizontal mouse
      // event.x = rotation around X axis (forward/back tilt) → vertical mouse
      // Values are in rad/s, multiply by sensitivity and time interval
      final dx = event.y * _sensitivity;
      final dy = event.x * _sensitivity;

      // Only send if there's meaningful movement
      if (dx.abs() > 0.1 || dy.abs() > 0.1) {
        _ws.sendRaw({
          'type': 'GYRO',
          'dx': double.parse(dx.toStringAsFixed(2)),
          'dy': double.parse(dy.toStringAsFixed(2)),
        });
      }
    });
  }

  /// Stop sending gyroscope data.
  void stop() {
    _subscription?.cancel();
    _subscription = null;
    _isActive = false;
    notifyListeners();

    // Notify PC to hide laser overlay
    _ws.sendCommand('LASER_OFF');
  }

  void toggle() {
    if (_isActive) {
      stop();
    } else {
      start();
    }
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}
