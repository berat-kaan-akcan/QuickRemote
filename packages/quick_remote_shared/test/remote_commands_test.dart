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
      RemoteCommands.slidePreview(true),
      RemoteCommands.slideThumb(4),
    ]) {
      expect(RemoteCommands.allowedPrefixes, contains(command.split(':').first), reason: command);
    }
    expect(RemoteCommands.startAt(3), 'START_AT:3');
    expect(RemoteCommands.keepInk(true), 'SET_KEEP_INK:1');
    expect(RemoteCommands.keepInk(false), 'SET_KEEP_INK:0');
    expect(RemoteCommands.slidePreview(true), 'SLIDE_PREVIEW:1');
    expect(RemoteCommands.slidePreview(false), 'SLIDE_PREVIEW:0');
    expect(RemoteCommands.slideThumb(4), 'SLIDE_THUMB:4');
  });

  test('plain commands and prefixes do not overlap', () {
    expect(RemoteCommands.allowedCommands.intersection(RemoteCommands.allowedPrefixes), isEmpty);
    expect(RemoteCommands.allowedCommands.where((c) => c.contains(':')), isEmpty);
  });

  group('isValid', () {
    test('takes every plain command and every builder\'s output', () {
      for (final command in RemoteCommands.allowedCommands) {
        expect(RemoteCommands.isValid(command), isTrue, reason: command);
      }
      for (final command in [
        RemoteCommands.startAt(3),
        RemoteCommands.penColor(0xFFFFFF),
        RemoteCommands.highlighterColor(0),
        RemoteCommands.volumeSet(100),
        RemoteCommands.keepInk(false),
        RemoteCommands.slidePreview(true),
        RemoteCommands.slideThumb(9999),
      ]) {
        expect(RemoteCommands.isValid(command), isTrue, reason: command);
      }
    });

    test('refuses what is not a command', () {
      for (final command in ['', 'FORMAT_C', 'next', 'NEXT:1', 'NEXT ', ' NEXT', 'NEXT\n']) {
        expect(RemoteCommands.isValid(command), isFalse, reason: command);
      }
    });

    test('a prefix takes only a short run of digits', () {
      for (final command in [
        'START_AT:',
        'START_AT:abc',
        'START_AT: 5',
        'START_AT:5\nNEXT',
        'START_AT:5:6',
        'START_AT:0x10',
        'START_AT:+5',
        'START_AT:-5',
        'START_AT:١٢', // Arabic-Indic digits
        'START_AT:1234567890',
        'SLIDE_PREVIEW:${'A' * 900}',
        'SET_PEN_COLOR:\u202e5',
        'UNKNOWN:5',
      ]) {
        expect(RemoteCommands.isValid(command), isFalse, reason: command);
      }
    });
  });
}
