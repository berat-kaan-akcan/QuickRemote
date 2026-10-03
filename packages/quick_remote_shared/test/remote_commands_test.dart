import 'package:quick_remote_shared/quick_remote_shared.dart';
import 'package:test/test.dart';

void main() {
  test('builders produce commands with an allowed prefix', () {
    for (final command in [
      RemoteCommands.startAt(3),
      RemoteCommands.penColor(0xFF),
      RemoteCommands.highlighterColor(0xFFFF),
      RemoteCommands.volumeSet(40),
      RemoteCommands.keepInk(true),
    ]) {
      expect(RemoteCommands.allowedPrefixes, contains(command.split(':').first), reason: command);
    }
    expect(RemoteCommands.startAt(3), 'START_AT:3');
    expect(RemoteCommands.keepInk(true), 'SET_KEEP_INK:1');
    expect(RemoteCommands.keepInk(false), 'SET_KEEP_INK:0');
  });

  test('plain commands and prefixes do not overlap', () {
    expect(RemoteCommands.allowedCommands.intersection(RemoteCommands.allowedPrefixes), isEmpty);
    expect(RemoteCommands.allowedCommands.where((c) => c.contains(':')), isEmpty);
  });
}
