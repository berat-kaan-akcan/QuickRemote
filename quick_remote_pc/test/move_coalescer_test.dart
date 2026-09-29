import 'package:flutter_test/flutter_test.dart';
import 'package:quick_remote_pc/services/server/move_coalescer.dart';

void main() {
  late List<(int, double, double)> moves;
  late MoveCoalescer coalescer;

  setUp(() {
    moves = [];
    coalescer = MoveCoalescer(
      minInterval: const Duration(milliseconds: 20),
      onMove: (type, dx, dy) => moves.add((type, dx, dy)),
    );
  });

  tearDown(() => coalescer.dispose());

  test('applies the first delta immediately', () {
    coalescer.add(0, 3, 4);
    expect(moves, [(0, 3.0, 4.0)]);
  });

  test('sums a burst instead of dropping it', () async {
    coalescer.add(0, 1, 1);
    coalescer.add(0, 2, -1);
    coalescer.add(0, 3, 5);
    expect(moves, [(0, 1.0, 1.0)]);

    await Future.delayed(const Duration(milliseconds: 60));
    expect(moves, [(0, 1.0, 1.0), (0, 5.0, 4.0)]);
  });

  test('never merges touch and laser motion', () {
    coalescer.add(0, 1, 1);
    coalescer.add(0, 2, 2); // pending
    coalescer.add(1, 7, 7); // flushes the pending touch first
    expect(moves.first, (0, 1.0, 1.0));
    expect(moves[1], (0, 2.0, 2.0));
  });

  test('dispose drops pending motion', () async {
    coalescer.add(0, 1, 1);
    coalescer.add(0, 9, 9);
    coalescer.dispose();
    await Future.delayed(const Duration(milliseconds: 60));
    expect(moves, [(0, 1.0, 1.0)]);
  });
}
