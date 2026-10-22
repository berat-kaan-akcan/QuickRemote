import 'package:flutter_test/flutter_test.dart';
import 'package:quick_remote_pc/services/input/linux/linux_input_service.dart';
import 'package:quick_remote_pc/services/input/linux/script_bridge.dart';
import 'package:quick_remote_pc/services/input/linux/x11_windows.dart';

class _NoBridge extends ScriptBridge {
  _NoBridge() : super('NoBridge', 'none.py');

  @override
  Future<String?> interpreter() async => null;

  @override
  Future<Map<String, dynamic>> request(
    String cmd, [
    Map<String, Object?> args = const {},
    Duration timeout = const Duration(seconds: 6),
  ]) async =>
      {'ok': false, 'error': 'NOT_RUNNING'};

  @override
  void send(String cmd, Map<String, Object?> args) {}
}

void main() {
  // LASER_ABS: the phone's finger on its slide picture puts the cursor, which
  // WPS's laser pen follows, at that point of the show's window.
  test('the cursor goes to the point of the WPS show, as a fraction of the desktop', () {
    final moves = <(double, double)>[];
    const show = X11Window(7, ['wpp', 'Wpp'], fullscreen: true);
    final service = LinuxInputService.withDependencies(
      impress: _NoBridge(),
      wps: _NoBridge(),
      activeWindow: () => show,
      clientWindows: () => const [show],
      keys: (_) {},
      // The show on the right one of two 1000×500 monitors.
      windowArea: (id) => id == 7 ? (x: 1000, y: 0, width: 1001, height: 501) : null,
      rootArea: () => (x: 0, y: 0, width: 2000, height: 500),
      moveCursor: (fx, fy) => moves.add((fx, fy)),
    );
    service.moveCursorInShow(0.5, 0.5);
    service.moveCursorInShow(1, 0);
    expect(moves, [(0.75, 0.5), (1.0, 0.0)]);
  });

  test('no show window: the cursor stays', () {
    final moves = <(double, double)>[];
    final service = LinuxInputService.withDependencies(
      impress: _NoBridge(),
      wps: _NoBridge(),
      activeWindow: () => null,
      clientWindows: () => const [],
      keys: (_) {},
      rootArea: () => (x: 0, y: 0, width: 2000, height: 500),
      moveCursor: (fx, fy) => moves.add((fx, fy)),
    );
    service.moveCursorInShow(0.5, 0.5);
    expect(moves, isEmpty);
  });
}
