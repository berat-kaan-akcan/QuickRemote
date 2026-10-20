import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import '../input/input_service.dart' show ScreenArea;
import 'laser_overlay.dart';

/// The overlay as its own process, `lib/quickremote_overlay` in the bundle
/// (linux/overlay/laser_overlay.cc): an XWayland override-redirect window,
/// so it needs X11 (DISPLAY), also on a Wayland session.
///
/// Lines on its stdin: `area X Y W H` (the monitor holding that window's
/// middle; bare `area`: the primary one), `show`, `move X Y` (fractions of
/// that monitor), `hide`, `ink begin pen|highlighter RRGGBB X Y`, `ink to
/// X Y`, `ink end`, `ink clear`, `spotlight on|off`, `blank RRGGBB|off`.
/// It answers
/// `ready W H` once, or `error <reason>` and exits.
class LinuxLaserOverlay implements LaserOverlay {
  LinuxLaserOverlay._();
  static final LinuxLaserOverlay instance = LinuxLaserOverlay._();

  static String get _helperPath => p.join(p.dirname(Platform.resolvedExecutable), 'lib', 'quickremote_overlay');

  Process? _process;
  Future<Process?>? _starting;

  /// Set when the helper could not start (no compositor, no XWayland): the
  /// program's own laser is used from then on.
  bool _failed = false;

  @override
  bool get supported => !_failed && Platform.environment['DISPLAY'] != null && File(_helperPath).existsSync();

  @override
  Future<bool> place(ScreenArea? area, {bool keep = false}) async {
    final process = _ensureProcess();
    // Before the strokes that follow, also while the helper starts.
    if (!keep) _write(area == null ? 'area' : 'area ${area.x} ${area.y} ${area.width} ${area.height}');
    return await process != null;
  }

  @override
  void show() => _write('show');

  @override
  void move(double relX, double relY) => _write('move ${_xy(relX, relY)}');

  @override
  void hide() => _write('hide');

  @override
  void inkBegin({required bool highlighter, required int rgb, required double relX, required double relY}) {
    final hex = (rgb & 0xFFFFFF).toRadixString(16).padLeft(6, '0');
    _write('ink begin ${highlighter ? 'highlighter' : 'pen'} $hex ${_xy(relX, relY)}');
  }

  @override
  void inkTo(double relX, double relY) => _write('ink to ${_xy(relX, relY)}');

  @override
  void inkEnd() => _write('ink end');

  @override
  void inkClear() => _write('ink clear');

  // A magnifier needs the screen's picture: on Wayland a portal asks the
  // user each session, and XWayland sees no native Wayland window.
  @override
  bool get supportsZoom => false;

  @override
  void zoom(bool on) {}

  @override
  void spotlight(bool on) => _write('spotlight ${on ? 'on' : 'off'}');

  @override
  void blank(int? rgb) =>
      _write(rgb == null ? 'blank off' : 'blank ${(rgb & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}');

  static String _xy(double x, double y) => '${x.toStringAsFixed(5)} ${y.toStringAsFixed(5)}';

  /// Lines written while the helper starts: the first stroke's, which come
  /// before its "ready".
  final List<String> _waiting = [];

  void _write(String line) {
    final process = _process;
    if (process == null) {
      if (_starting != null) _waiting.add(line);
      return;
    }
    try {
      process.stdin.writeln(line);
    } catch (_) {
      _process = null;
    }
  }

  Future<Process?> _ensureProcess() {
    if (_process != null) return Future.value(_process);
    if (!supported) return Future.value(null);
    return _starting ??= _start().whenComplete(() => _starting = null);
  }

  Future<Process?> _start() async {
    final Process process;
    try {
      // The Flutter window is on Wayland; the overlay must be an X11 window.
      process = await Process.start(_helperPath, const [], environment: {'GDK_BACKEND': 'x11'});
    } catch (e) {
      debugPrint('LaserOverlay: failed to start: $e');
      _failed = true;
      LaserOverlaySettings.overlayFailed();
      return null;
    }
    final ready = Completer<bool>();
    process.stdout.transform(utf8.decoder).transform(const LineSplitter()).listen((line) {
      if (line.startsWith('ready')) {
        if (!ready.isCompleted) ready.complete(true);
      } else if (line.startsWith('error')) {
        debugPrint('LaserOverlay: $line');
        if (!ready.isCompleted) ready.complete(false);
      }
    });
    process.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) => debugPrint('LaserOverlay stderr: $line'));
    // A write after the process exited fails here, not at writeln.
    process.stdin.done.catchError((_) {});
    process.exitCode.then((code) {
      debugPrint('LaserOverlay exited with code $code');
      if (!ready.isCompleted) ready.complete(false);
      if (identical(_process, process)) _process = null;
    });

    final ok = await ready.future.timeout(const Duration(seconds: 3), onTimeout: () => false);
    final waiting = List.of(_waiting);
    _waiting.clear();
    if (!ok) {
      _failed = true;
      LaserOverlaySettings.overlayFailed();
      process.kill();
      return null;
    }
    _process = process;
    waiting.forEach(_write);
    return process;
  }
}
