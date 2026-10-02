import 'package:flutter_test/flutter_test.dart';
import 'package:quick_remote_pc/services/input/command_router.dart';
import 'package:quick_remote_shared/quick_remote_shared.dart';

import 'fakes.dart';

void main() {
  late FakeInputService service;

  setUp(() => service = FakeInputService());

  List<String> run(String command) {
    CommandRouter.execute(service, command);
    return service.calls;
  }

  test('every allowed command reaches exactly one InputService method', () {
    // REFRESH_STATE is handled by the server itself, never routed.
    for (final command in RemoteCommands.allowedCommands.difference({RemoteCommands.refreshState})) {
      service.calls.clear();
      expect(run(command), hasLength(1), reason: command);
    }
  });

  test('different commands map to different methods', () {
    final methods = <String, String>{};
    for (final command in RemoteCommands.allowedCommands.difference({
      RemoteCommands.refreshState,
      RemoteCommands.laserCursor, // legacy alias
    })) {
      service.calls.clear();
      final method = run(command).single;
      expect(methods[method], isNull, reason: '$command and ${methods[method]} both call $method');
      methods[method] = command;
    }
  });

  group('prefix commands', () {
    test('START_AT accepts 1..9999', () {
      expect(run('START_AT:1'), ['slideStartAt:1']);
      service.calls.clear();
      expect(run('START_AT:9999'), ['slideStartAt:9999']);
      service.calls.clear();
      expect(run('START_AT:0'), isEmpty);
      expect(run('START_AT:10000'), isEmpty);
      expect(run('START_AT:-3'), isEmpty);
      expect(run('START_AT:1e3'), isEmpty);
      expect(run('START_AT:'), isEmpty);
    });

    test('VOLUME_SET accepts 0..100', () {
      expect(run('VOLUME_SET:0'), ['setVolume:0']);
      service.calls.clear();
      expect(run('VOLUME_SET:100'), ['setVolume:100']);
      service.calls.clear();
      expect(run('VOLUME_SET:101'), isEmpty);
      expect(run('VOLUME_SET:50;LOCK'), isEmpty);
    });

    test('SET_PEN_COLOR accepts 24-bit values only', () {
      expect(run('SET_PEN_COLOR:16777215'), ['setPenColor:16777215']);
      service.calls.clear();
      expect(run('SET_PEN_COLOR:16777216'), isEmpty);
      expect(run('SET_PEN_COLOR'), isEmpty);
    });
  });

  test('ignores unknown commands', () {
    expect(run('RM_RF'), isEmpty);
  });
}
