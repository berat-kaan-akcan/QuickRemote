import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quick_remote_pc/services/powershell_runner.dart';

/// A stand-in for `powershell.exe`: keeps what the runner writes to its
/// stdin and prints what the test tells it to.
class _FakeProcess implements Process {
  final _stdin = _FakeStdin();
  final _stdout = StreamController<List<int>>();
  final _stderr = StreamController<List<int>>();
  final _exit = Completer<int>();
  bool killed = false;

  /// The lines written so far.
  List<String> get written => _stdin.lines;

  /// The marker of the job the runner wrote last.
  String get marker {
    final line = written.lastWhere(
      (l) => l.startsWith('Write-Output "___PS_DONE_'),
    );
    return line.substring('Write-Output "'.length, line.length - 1);
  }

  /// How many jobs were written to this process.
  int get jobs =>
      written.where((l) => l.startsWith('Write-Output "___PS_DONE_')).length;

  void print(String text) => _stdout.add(utf8.encode(text));

  @override
  IOSink get stdin => _stdin;
  @override
  Stream<List<int>> get stdout => _stdout.stream;
  @override
  Stream<List<int>> get stderr => _stderr.stream;
  @override
  Future<int> get exitCode => _exit.future;
  @override
  int get pid => 1;
  @override
  bool kill([ProcessSignal signal = ProcessSignal.sigterm]) {
    killed = true;
    if (!_exit.isCompleted) _exit.complete(-9);
    return true;
  }
}

class _FakeStdin implements IOSink {
  final lines = <String>[];

  @override
  void writeln([Object? object = '']) => lines.add('$object');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late List<_FakeProcess> started;

  PowerShellRunner runner({Duration timeout = const Duration(seconds: 5)}) =>
      PowerShellRunner(
        'Test',
        start: () async {
          final process = _FakeProcess();
          started.add(process);
          return process;
        },
        timeout: timeout,
        firstTimeout: timeout,
      );

  /// Waits until [count] jobs were written to [process].
  Future<void> written(_FakeProcess Function() process, int count) async {
    while (started.isEmpty || process().jobs < count) {
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
  }

  setUp(() => started = []);

  test('every job gets its own random marker', () async {
    final ps = runner();
    final first = ps.run('one');
    await written(() => started.single, 1);
    final markerOne = started.single.marker;
    started.single.print('1\n$markerOne\n');
    expect(await first, '1');

    final second = ps.run('two');
    await written(() => started.single, 2);
    final markerTwo = started.single.marker;
    started.single.print('2\n$markerTwo\n');
    expect(await second, '2');

    expect(markerOne, matches(RegExp(r'^___PS_DONE_[0-9a-f]{32}___$')));
    expect(markerTwo, isNot(markerOne));
    expect(PowerShellRunner.newMarker(), isNot(PowerShellRunner.newMarker()));
  });

  test(
    'a marker-like line in the output (slide notes) does not end the job',
    () async {
      final ps = runner();
      final notes = ps.run('notes');
      final next = ps.run('state');
      await written(() => started.single, 1);
      final process = started.single;
      final marker = process.marker;

      // Notes broken into lines that copy the old fixed marker, the new
      // one's shape, and a real marker cut by every kind of line break.
      final half = marker.length ~/ 2;
      process.print(
        'first line\n'
        '___PS_DONE___\n'
        '  ___PS_DONE___  \r\n'
        '___PS_DONE_${'0' * 32}___\n'
        '${PowerShellRunner.newMarker()}\r'
        '${marker.substring(0, half)}\n${marker.substring(half)}\n'
        'x$marker\n'
        'last line\n',
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));
      // Still the first job: the second one was not written yet.
      expect(process.jobs, 1);

      process.print('$marker\n');
      final output = await notes;
      expect(output, startsWith('first line\n___PS_DONE___\n'));
      expect(output, endsWith('last line'));
      expect(const LineSplitter().convert(output), hasLength(9));

      // The next job gets its own answer, not the rest of the notes.
      await written(() => process, 2);
      process.print('{"current":3}\n${process.marker}\n');
      expect(await next, '{"current":3}');
    },
  );

  test('a marker split over two chunks still ends the job', () async {
    final ps = runner();
    final job = ps.run('one');
    await written(() => started.single, 1);
    final marker = started.single.marker;
    started.single.print('out\n${marker.substring(0, 10)}');
    started.single.print('${marker.substring(10)}\r\n');
    expect(await job, 'out');
  });

  test(
    'a timed-out job answers empty and its late marker ends no later job',
    () async {
      final ps = runner(timeout: const Duration(milliseconds: 100));
      final slow = ps.run('slow');
      await written(() => started[0], 1);
      final first = started[0];
      final slowMarker = first.marker;

      expect(await slow, '');
      expect(first.killed, isTrue);

      final next = ps.run('next');
      await written(() => started[1], 1);
      final second = started[1];
      expect(second.marker, isNot(slowMarker));

      // The given-up job's output and marker arrive late, from the old
      // process and (were it ever to happen) from the new one too.
      first.print('late\n$slowMarker\n');
      second.print('late\n$slowMarker\n');
      var done = false;
      unawaited(next.then((_) => done = true));
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(done, isFalse);

      second.print('answer\n${second.marker}\n');
      expect(await next, 'late\n$slowMarker\nanswer');
    },
  );

  test('lines printed between two jobs do not lead the next answer', () async {
    final ps = runner();
    final first = ps.run('one');
    await written(() => started.single, 1);
    final process = started.single;
    process.print('1\n${process.marker}\n');
    expect(await first, '1');

    process.print('stray\n');
    await Future<void>.delayed(const Duration(milliseconds: 20));
    final second = ps.run('two');
    await written(() => process, 2);
    process.print('2\n${process.marker}\n');
    expect(await second, '2');
  });

  test(
    'a process that dies mid-job fails that job and the next one starts another',
    () async {
      final ps = runner();
      final first = ps.run('one');
      await written(() => started[0], 1);
      started[0].kill();
      expect(await first, '');

      final second = ps.run('two');
      await written(() => started[1], 1);
      started[1].print('2\n${started[1].marker}\n');
      expect(await second, '2');
    },
  );
}
