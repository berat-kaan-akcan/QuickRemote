import 'dart:async';

/// Rate-limits relative mouse motion without losing any of it.
///
/// The phone sends deltas, not positions, so a dropped packet is lost cursor
/// movement. Phones' Wi-Fi often delivers packets in bursts; deltas arriving
/// faster than [minInterval] are summed and applied in the next slot instead.
class MoveCoalescer {
  MoveCoalescer({required this.minInterval, required this.onMove});

  final Duration minInterval;
  final void Function(int type, double dx, double dy) onMove;

  final Stopwatch _clock = Stopwatch()..start();
  Duration? _lastApplied;
  Timer? _timer;
  int _type = 0;
  double _dx = 0;
  double _dy = 0;
  bool _hasPending = false;

  void add(int type, double dx, double dy) {
    // TOUCH and LASER move differently on the PC; never sum them together.
    if (_hasPending && type != _type) flush();
    _type = type;
    _dx += dx;
    _dy += dy;
    _hasPending = true;

    final last = _lastApplied;
    final elapsed = last == null ? minInterval : _clock.elapsed - last;
    if (elapsed >= minInterval) {
      flush();
    } else {
      _timer ??= Timer(minInterval - elapsed, flush);
    }
  }

  /// Applies whatever is pending right away.
  void flush() {
    _timer?.cancel();
    _timer = null;
    if (!_hasPending) return;
    final type = _type;
    final dx = _dx;
    final dy = _dy;
    _dx = 0;
    _dy = 0;
    _hasPending = false;
    _lastApplied = _clock.elapsed;
    onMove(type, dx, dy);
  }

  /// Drops pending motion; used when the client disconnects.
  void dispose() {
    _timer?.cancel();
    _timer = null;
    _hasPending = false;
  }
}
