import 'package:flutter_test/flutter_test.dart';
import 'package:quick_remote_app/services/presentation_timer_controller.dart';

void main() {
  late DateTime now;
  late PresentationTimerController timer;
  late List<TimerAlert> alerts;

  void advance(int seconds) {
    now = now.add(Duration(seconds: seconds));
    timer.tick();
  }

  setUp(() {
    now = DateTime(2026, 10, 2, 12);
    timer = PresentationTimerController(clock: () => now);
    alerts = [];
    timer.onAlert = alerts.add;
    timer.warningTimes = () => const [60, 30];
  });

  tearDown(() => timer.dispose());

  test('reset goes back to the selected duration, not to zero', () {
    timer.setDuration(120, start: true);
    advance(50);
    expect(timer.displaySeconds, 70);

    timer.reset();
    expect(timer.isRunning, false);
    expect(timer.isDurationSelected, true);
    expect(timer.targetSeconds, 120);
    expect(timer.displaySeconds, 120);
  });

  test('setDuration starts at once only when asked', () {
    timer.setDuration(90);
    expect(timer.isRunning, false);
    timer.setDuration(45, start: true);
    expect(timer.isRunning, true);
    expect(timer.displaySeconds, 45);
  });

  test('pause keeps the elapsed time and resume continues from it', () {
    timer.setDuration(100, start: true);
    advance(10);
    timer.pause();
    now = now.add(const Duration(seconds: 30)); // paused time does not count
    timer.start();
    advance(5);
    expect(timer.elapsedSeconds, 15);
  });

  test('warnings fire even when ticks skip the exact second', () {
    timer.setDuration(120, start: true);
    advance(50); // 70 left
    advance(15); // 55 left: passed 60 without hitting it
    expect(alerts.map((a) => (a.kind, a.remainingSeconds)), [(TimerAlertKind.warning, 60)]);

    advance(55); // 0 left: passed 30 and the end in one tick
    expect(alerts.last.kind, TimerAlertKind.timeUp);
    expect(alerts, hasLength(2));

    advance(10);
    expect(timer.isOvertime, true);
    expect(timer.displaySeconds, 10);
    expect(alerts, hasLength(2));
  });

  test('free mode counts up without alerts', () {
    timer.setDuration(0, start: true);
    advance(100);
    expect(timer.displaySeconds, 100);
    expect(timer.isOvertime, false);
    expect(alerts, isEmpty);
  });
}
