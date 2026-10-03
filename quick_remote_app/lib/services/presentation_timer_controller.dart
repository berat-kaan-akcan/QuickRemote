import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';

enum TimerAlertKind { warning, timeUp }

/// A warning threshold or the end of the selected duration was reached.
class TimerAlert {
  final TimerAlertKind kind;

  /// Seconds left when the alert fired: the warning threshold, or 0.
  final int remainingSeconds;

  const TimerAlert(this.kind, this.remainingSeconds);
}

/// State of the presentation timer. The remote screen owns it, so the timer
/// keeps running while the user switches between the tabs that show it.
class PresentationTimerController extends ChangeNotifier {
  PresentationTimerController({DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;
  Timer? _ticker;
  DateTime? _startTime;
  int _elapsedSeconds = 0;
  int _targetSeconds = 0; // 0 means just count up
  bool _isRunning = false;
  bool _isDurationSelected = false;

  /// Seconds before the end at which to warn. Read on every tick, so a
  /// change in the settings applies to a running timer.
  List<int> Function() warningTimes = () => const [];

  void Function(TimerAlert alert)? onAlert;

  int get elapsedSeconds => _elapsedSeconds;
  int get targetSeconds => _targetSeconds;
  bool get isRunning => _isRunning;
  bool get isDurationSelected => _isDurationSelected;
  bool get isOvertime => _targetSeconds > 0 && _elapsedSeconds > _targetSeconds;

  /// Counts down to the target, then up past it; counts up without a target.
  int get displaySeconds =>
      _targetSeconds > 0 ? (_targetSeconds - _elapsedSeconds).abs() : _elapsedSeconds;

  /// Selects a duration ([seconds] 0 = count up) and stops the timer at its start.
  void setDuration(int seconds, {bool start = false}) {
    _ticker?.cancel();
    _isRunning = false;
    _targetSeconds = seconds;
    _elapsedSeconds = 0;
    _startTime = null;
    _isDurationSelected = true;
    if (start) {
      this.start();
    } else {
      notifyListeners();
    }
  }

  void start() {
    if (_isRunning) return;
    _isRunning = true;
    _startTime = _clock().subtract(Duration(seconds: _elapsedSeconds));
    // Elapsed time comes from the clock, not from counting ticks, so the
    // timer is right again at once when the app returns from the background.
    _ticker = Timer.periodic(const Duration(milliseconds: 500), (_) => tick());
    notifyListeners();
  }

  void pause() {
    if (!_isRunning) return;
    tick();
    _ticker?.cancel();
    _isRunning = false;
    notifyListeners();
  }

  /// Stops and goes back to the start of the selected duration.
  void reset() {
    _ticker?.cancel();
    _isRunning = false;
    _elapsedSeconds = 0;
    _startTime = null;
    notifyListeners();
  }

  @visibleForTesting
  void tick() {
    if (!_isRunning || _startTime == null) return;
    final elapsed = _clock().difference(_startTime!).inSeconds;
    if (elapsed == _elapsedSeconds) return;
    final before = _elapsedSeconds;
    _elapsedSeconds = elapsed;
    if (_targetSeconds > 0) _checkAlerts(_targetSeconds - before, _targetSeconds - elapsed);
    notifyListeners();
  }

  void _checkAlerts(int remainingBefore, int remainingNow) {
    // Ticks skip seconds while the app is in the background: look for the
    // thresholds passed since the last tick, not for an exact hit.
    bool passed(int threshold) => remainingBefore > threshold && remainingNow <= threshold;
    if (passed(0)) {
      onAlert?.call(const TimerAlert(TimerAlertKind.timeUp, 0));
      return;
    }
    final warnings = warningTimes().where(passed);
    if (warnings.isNotEmpty) {
      onAlert?.call(TimerAlert(TimerAlertKind.warning, warnings.reduce(math.min)));
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
