import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quick_remote_app/services/discovery_service.dart';
import 'package:quick_remote_app/services/launch_actions.dart';
import 'package:quick_remote_app/services/websocket_service.dart';

Map<String, dynamic> _recent(
  String host, {
  int port = 8765,
  String pin = '123456',
  String name = 'Office-PC',
}) => {'host': host, 'port': port, 'pin': pin, 'name': name};

DiscoveredDevice _found(
  String ip, {
  int port = 8765,
  String name = 'Office-PC',
}) => DiscoveredDevice(name: name, ip: ip, port: port);

/// A connector that answers from [answers] by host, and records each try.
class _Connector {
  _Connector(this.answers);
  final Map<String, ConnectionError?> answers;
  final tries = <(String, int, String, String?)>[];

  Future<ConnectionError?> call(PcAddress pc, String? fingerprint) async {
    tries.add((pc.host, pc.port, pc.pin, fingerprint));
    return answers.containsKey(pc.host)
        ? answers[pc.host]
        : ConnectionError.serverNotFound;
  }
}

Future<String?> _fingerprints(String host) async =>
    {'192.168.1.10': 'abc123'}[host];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LaunchAction.handles', () {
    test('a remote in use keeps its screen: the link only brings the app back', () {
      expect(LaunchAction.handles(remoteInUse: true), isFalse);
      expect(LaunchAction.handles(remoteInUse: false), isTrue);
    });
  });

  group('LaunchAction.parse', () {
    test('reads the three links', () {
      expect(
        LaunchAction.parse('quickremote://connect/last'),
        LaunchAction.connectLast,
      );
      expect(
        LaunchAction.parse('quickremote://bluetooth'),
        LaunchAction.bluetooth,
      );
      expect(LaunchAction.parse('quickremote://scan'), LaunchAction.scan);
      expect(LaunchAction.parse('quickremote://scan/'), LaunchAction.scan);
    });

    test('ignores anything else', () {
      for (final link in [
        null,
        '',
        'quickremote://watch',
        'quickremote://connect',
        'quickremote://connect/other',
        'https://connect/last',
        'quickremote://bluetooth/x',
      ]) {
        expect(LaunchAction.parse(link), isNull, reason: '$link');
      }
    });
  });

  group('PcAddress.fromRecent', () {
    test('needs an address and a saved PIN', () {
      expect(PcAddress.fromRecent(null), isNull);
      expect(PcAddress.fromRecent(_recent('10.0.0.2', pin: '')), isNull);
      expect(PcAddress.fromRecent({'host': '10.0.0.2', 'port': 1}), isNull);
      expect(
        PcAddress.fromRecent(_recent('10.0.0.2')),
        const PcAddress(
          host: '10.0.0.2',
          port: 8765,
          pin: '123456',
          name: 'Office-PC',
        ),
      );
    });

    test('a PC saved without a name goes by its address', () {
      expect(
        PcAddress.fromRecent(_recent('10.0.0.2', name: ''))!.name,
        '10.0.0.2',
      );
    });
  });

  group('LastPcConnect.run', () {
    Future<LastPcOutcome> run(
      List<Map<String, dynamic>> recent,
      _Connector connector, {
      List<DiscoveredDevice> Function()? found,
    }) => LastPcConnect.run(
      recent: recent,
      found: found ?? () => const [],
      fingerprintOf: _fingerprints,
      connect: connector.call,
      searchFor: const Duration(milliseconds: 60),
      pollEvery: const Duration(milliseconds: 10),
    );

    test('no recent PC, or none with a PIN', () async {
      final connector = _Connector({});
      expect(await run([], connector), isA<LastPcMissing>());
      expect(
        await run([_recent('192.168.1.10', pin: '')], connector),
        isA<LastPcMissing>(),
      );
      expect(connector.tries, isEmpty);
    });

    test('connects to the last PC at its saved address', () async {
      final connector = _Connector({'192.168.1.10': null});
      final outcome = await run([
        _recent('192.168.1.10'),
        _recent('192.168.1.20', name: 'Other'),
      ], connector);
      expect(outcome, isA<LastPcConnected>());
      outcome as LastPcConnected;
      expect(outcome.pc.host, '192.168.1.10');
      expect(outcome.movedFrom, isNull);
      // The client uses the certificate pinned for the address itself.
      expect(connector.tries, [('192.168.1.10', 8765, '123456', null)]);
    });

    test('a PC mDNS already sees at a new address is tried there at once, '
        'with the old address\'s certificate pinned', () async {
      final connector = _Connector({'192.168.1.33': null});
      final outcome = await run(
        [_recent('192.168.1.10')],
        connector,
        found: () => [_found('192.168.1.33', port: 9000)],
      );
      outcome as LastPcConnected;
      expect(outcome.pc.host, '192.168.1.33');
      expect(outcome.pc.port, 9000);
      expect(outcome.pc.pin, '123456');
      expect(outcome.movedFrom!.host, '192.168.1.10');
      expect(connector.tries, [('192.168.1.33', 9000, '123456', 'abc123')]);
    });

    test('the saved address does not answer: waits for mDNS', () async {
      final connector = _Connector({'192.168.1.33': null});
      var polls = 0;
      final outcome = await run(
        [_recent('192.168.1.10')],
        connector,
        found: () => ++polls < 3 ? const [] : [_found('192.168.1.33')],
      );
      outcome as LastPcConnected;
      expect(outcome.pc.host, '192.168.1.33');
      expect(connector.tries.map((t) => t.$1), [
        '192.168.1.10',
        '192.168.1.33',
      ]);
      expect(connector.tries.last.$4, 'abc123');
    });

    test('found neither at its address nor by name', () async {
      final connector = _Connector({});
      final outcome = await run(
        [_recent('192.168.1.10')],
        connector,
        found: () => [_found('192.168.1.40', name: 'Someone-else')],
      );
      expect(outcome, isA<LastPcNotFound>());
      expect((outcome as LastPcNotFound).pc.name, 'Office-PC');
      expect(connector.tries, hasLength(1));
    });

    test('a PC saved without a name is not searched for', () async {
      final connector = _Connector({});
      final outcome = await run(
        [_recent('192.168.1.10', name: '192.168.1.10')],
        connector,
        found: () => [_found('192.168.1.33', name: '192.168.1.10')],
      );
      expect(outcome, isA<LastPcNotFound>());
      expect(connector.tries, hasLength(1));
    });

    test('a wrong PIN is final: no search', () async {
      final connector = _Connector({'192.168.1.10': ConnectionError.wrongPin});
      var polls = 0;
      final outcome = await run(
        [_recent('192.168.1.10')],
        connector,
        found: () {
          polls++;
          return const [];
        },
      );
      expect(polls, 1); // the look before the first try only
      expect(outcome, isA<LastPcFailed>());
      expect((outcome as LastPcFailed).error, ConnectionError.wrongPin);
      expect(connector.tries, hasLength(1));
    });

    test('another PC under the name fails on the pinned certificate', () async {
      final connector = _Connector({
        '192.168.1.33': ConnectionError.certRejected,
      });
      final outcome = await run(
        [_recent('192.168.1.10')],
        connector,
        found: () => [_found('192.168.1.33')],
      );
      outcome as LastPcFailed;
      expect(outcome.error, ConnectionError.certRejected);
      expect(outcome.pc.host, '192.168.1.33');
    });
  });

  group('LaunchActions channel', () {
    const channel = MethodChannel('test/launch');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    late List<MethodCall> calls;
    String? initial;

    setUp(() {
      calls = [];
      initial = null;
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        return call.method == 'initialAction' ? initial : null;
      });
    });

    tearDown(() => messenger.setMockMethodCallHandler(channel, null));

    Future<ByteData?> sendAction(String link) {
      const codec = StandardMethodCodec();
      return messenger.handlePlatformMessage(
        channel.name,
        codec.encodeMethodCall(MethodCall('action', link)),
        (_) {},
      );
    }

    test('hands over the link the app was opened with', () async {
      initial = 'quickremote://scan';
      final actions = LaunchActions(channel: channel);
      final got = <LaunchAction>[];
      await actions.listen(got.add);
      expect(got, [LaunchAction.scan]);
      expect(calls.single.method, 'initialAction');
      await actions.listen(null);
    });

    test('links that come later go to the listener', () async {
      final actions = LaunchActions(channel: channel);
      final got = <LaunchAction>[];
      await actions.listen(got.add);
      await sendAction('quickremote://connect/last');
      await sendAction('quickremote://nothing');
      expect(got, [LaunchAction.connectLast]);
      await actions.listen(null);
    });

    test('tells the native side the last PC and the connection', () async {
      final actions = LaunchActions(channel: channel);
      await actions.setLastPc('Office-PC');
      final ws = WebSocketService();
      actions.watchConnection(ws);
      await Future<void>.delayed(Duration.zero);
      expect(calls.map((c) => c.method), ['lastPc', 'connected']);
      expect(calls[0].arguments, {'name': 'Office-PC'});
      expect(calls[1].arguments, {'connected': false});
      ws.dispose();
    });

    test('a missing native side is no error', () async {
      final actions = LaunchActions(
        channel: const MethodChannel('test/launch-none'),
      );
      await actions.setLastPc(null);
      await actions.listen((_) {});
      await actions.listen(null);
    });
  });
}
