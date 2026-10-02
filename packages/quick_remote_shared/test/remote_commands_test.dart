import 'package:quick_remote_shared/quick_remote_shared.dart';
import 'package:test/test.dart';

void main() {
  test('builders produce commands with an allowed prefix', () {
    for (final command in [
      RemoteCommands.startAt(3),
      RemoteCommands.penColor(0xFF),
      RemoteCommands.volumeSet(40),
    ]) {
      expect(RemoteCommands.allowedPrefixes, contains(command.split(':').first), reason: command);
    }
    expect(RemoteCommands.startAt(3), 'START_AT:3');
  });

  test('plain commands and prefixes do not overlap', () {
    expect(RemoteCommands.allowedCommands.intersection(RemoteCommands.allowedPrefixes), isEmpty);
    expect(RemoteCommands.allowedCommands.where((c) => c.contains(':')), isEmpty);
  });
}
