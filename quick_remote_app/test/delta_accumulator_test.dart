import 'package:flutter_test/flutter_test.dart';
import 'package:quick_remote_app/utils/delta_accumulator.dart';

void main() {
  test('returns nothing when empty', () {
    final acc = DeltaAccumulator(maxStep: 500);
    expect(acc.take(), isNull);
  });

  test('sums small deltas into one step', () {
    final acc = DeltaAccumulator(maxStep: 500)
      ..add(10, -4)
      ..add(5, 1);
    expect(acc.take(), (15.0, -3.0));
    expect(acc.take(), isNull);
  });

  test('splits a fast swipe into steps the PC accepts, losing nothing', () {
    final acc = DeltaAccumulator(maxStep: 500)..add(1200, -700);
    final steps = <(double, double)>[];
    for (var s = acc.take(); s != null; s = acc.take()) {
      steps.add(s);
    }
    expect(steps, [(500.0, -500.0), (500.0, -200.0), (200.0, 0.0)]);
    expect(steps.fold<double>(0, (sum, s) => sum + s.$1), 1200);
    expect(steps.fold<double>(0, (sum, s) => sum + s.$2), -700);
  });

  test('clear drops pending motion', () {
    final acc = DeltaAccumulator(maxStep: 500)
      ..add(3, 3)
      ..clear();
    expect(acc.isEmpty, isTrue);
    expect(acc.take(), isNull);
  });
}
