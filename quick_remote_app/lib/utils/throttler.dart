import 'dart:async';
import 'package:flutter/foundation.dart';

/// A utility class that limits the rate at which a function can be called.
/// Uses leading-edge throttling: the first call executes immediately,
/// subsequent calls within the delay window are dropped.
class EventThrottler {
  final Duration delay;
  Timer? _timer;

  EventThrottler({required this.delay});

  /// Executes the given [action] immediately on the first call (leading edge).
  /// Subsequent calls within the [delay] window are ignored.
  void throttle(VoidCallback action) {
    if (_timer?.isActive ?? false) return;

    action(); // Execute immediately (leading edge)
    _timer = Timer(delay, () => _timer = null);
  }

  /// Cancels any pending scheduled actions.
  void cancel() {
    _timer?.cancel();
    _timer = null;
  }
}
