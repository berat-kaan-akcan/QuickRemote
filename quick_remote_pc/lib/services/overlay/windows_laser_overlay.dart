import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../input/input_service.dart' show ScreenArea;
import 'laser_overlay.dart';

/// The overlay windows of the Windows runner (windows/runner/laser_overlay.cpp):
/// the dot in a small layered window moved with the laser, the ink in one
/// as large as the monitor.
class WindowsLaserOverlay implements LaserOverlay {
  WindowsLaserOverlay._();
  static final WindowsLaserOverlay instance = WindowsLaserOverlay._();

  static const _channel = MethodChannel('com.quickremote.quick_remote_pc/overlay');

  /// Set when the runner has no overlay or could not make its windows.
  bool _failed = false;
  bool _placed = false;

  /// Calls go one after the other: a stroke never reaches the runner before
  /// the monitor it is drawn on.
  Future<void> _queue = Future.value();

  @override
  bool get supported => !_failed;

  @override
  Future<bool> place(ScreenArea? area, {bool keep = false}) async {
    if (_failed) return false;
    if (keep && _placed) return true;
    final placed = _queue.then(
      (_) => _channel.invokeMethod<bool>(
        'area',
        area == null ? null : {'x': area.x, 'y': area.y, 'width': area.width, 'height': area.height},
      ),
    );
    _queue = placed.then((_) {}, onError: (Object _) {});
    try {
      if (await placed == true) return _placed = true;
    } on MissingPluginException {
      // A runner from before the overlay.
    } on PlatformException catch (e) {
      debugPrint('LaserOverlay: $e');
    }
    _failed = true;
    LaserOverlaySettings.overlayFailed();
    return false;
  }

  @override
  void show() => _call('show');

  @override
  void move(double relX, double relY) => _call('move', {'x': relX, 'y': relY});

  @override
  void hide() => _call('hide');

  @override
  void inkBegin({required bool highlighter, required int rgb, required double relX, required double relY}) =>
      _call('inkBegin', {'highlighter': highlighter, 'rgb': rgb & 0xFFFFFF, 'x': relX, 'y': relY});

  @override
  void inkTo(double relX, double relY) => _call('inkTo', {'x': relX, 'y': relY});

  @override
  void inkEnd() => _call('inkEnd');

  @override
  void inkClear() => _call('inkClear');

  @override
  bool get supportsZoom => supported;

  @override
  void zoom(bool on) => _call('zoom', {'on': on});

  @override
  void spotlight(bool on) => _call('spotlight', {'on': on});

  @override
  void blank(int? rgb) => _call('blank', rgb == null ? null : {'rgb': rgb & 0xFFFFFF});

  void _call(String method, [Object? args]) {
    if (_failed) return;
    _queue = _queue.then((_) => _channel.invokeMethod<void>(method, args)).catchError((Object e) {
      debugPrint('LaserOverlay $method: $e');
    });
  }
}
