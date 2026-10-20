import 'package:flutter/foundation.dart';

import '../input/input_service.dart' show ScreenArea;

/// Who draws the laser (Settings → Laser, the `laser_overlay` preference).
enum LaserOverlayMode {
  /// QuickRemote's overlay, except in the programs whose own laser works
  /// well ([OverlayInputService.ownLaser]: PowerPoint, WPS).
  auto,

  /// QuickRemote's overlay in every program.
  always,

  /// The program's own laser, only during a slideshow (as before the overlay).
  never;

  static LaserOverlayMode fromName(String? name) => values.firstWhere((m) => m.name == name, orElse: () => auto);
}

/// The PC's choice, set by LaserOverlayProvider; read on every laser command.
class LaserOverlaySettings {
  LaserOverlaySettings._();

  static LaserOverlayMode _mode = LaserOverlayMode.auto;
  static final _changes = _Changes();

  static LaserOverlayMode get mode => _mode;
  static set mode(LaserOverlayMode mode) {
    if (mode == _mode) return;
    _mode = mode;
    _changes.tell();
  }

  /// Told when [mode] changes or the overlay turns out not to work, so
  /// whether the laser works outside a show may have changed: the server
  /// tells the phones (OVERLAY).
  static Listenable get changes => _changes;

  /// The overlay could not start on this PC.
  static void overlayFailed() => _changes.tell();
}

class _Changes extends ChangeNotifier {
  void tell() => notifyListeners();
}

/// A see-through window above every other one, which draws the laser dot
/// and ink without moving the OS cursor or pressing a key. Positions are
/// fractions of its monitor (0..1). It keeps no ink of its own worth
/// trusting: OverlayInputService keeps the strokes and draws them again.
abstract class LaserOverlay {
  /// Whether this PC can show one; false once it failed to start.
  bool get supported;

  /// Whether it has a magnifier ([zoom]): Windows only.
  bool get supportsZoom;

  /// Starts the overlay and puts it on the monitor of [area] (the show's
  /// window), else on the primary one; a new monitor drops the ink. With
  /// [keep] it stays where it is. False when it could not start.
  Future<bool> place(ScreenArea? area, {bool keep = false});

  /// The laser dot, from the next [move].
  void show();

  /// The dot's position.
  void move(double relX, double relY);

  /// No dot.
  void hide();

  /// A new stroke in [rgb] (0xRRGGBB), see-through for the [highlighter].
  void inkBegin({required bool highlighter, required int rgb, required double relX, required double relY});

  void inkTo(double relX, double relY);

  void inkEnd();

  /// No ink.
  void inkClear();

  /// The screen darkened but for a circle at the dot's place ([move]), in
  /// place of the dot; off, the dot again if [show] was called.
  void spotlight(bool on);

  /// The whole screen in [rgb] (0xRRGGBB, black or white), above the ink;
  /// null: the screen again.
  void blank(int? rgb);

  /// A round magnifier at the dot's place ([move]), in place of the dot.
  void zoom(bool on);
}
