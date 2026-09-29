/// Sums touch deltas and hands them out in steps no larger than [maxStep] per
/// axis, keeping the remainder. A fast swipe is split up instead of being
/// rejected by the receiver, and nothing is lost between sends.
class DeltaAccumulator {
  DeltaAccumulator({required this.maxStep});

  final double maxStep;
  double _dx = 0;
  double _dy = 0;

  bool get isEmpty => _dx == 0 && _dy == 0;

  void add(double dx, double dy) {
    _dx += dx;
    _dy += dy;
  }

  /// Removes and returns the next step, or null when nothing is pending.
  (double, double)? take() {
    if (isEmpty) return null;
    final dx = _dx.clamp(-maxStep, maxStep);
    final dy = _dy.clamp(-maxStep, maxStep);
    _dx -= dx;
    _dy -= dy;
    return (dx, dy);
  }

  void clear() {
    _dx = 0;
    _dy = 0;
  }
}
