import 'package:flutter_test/flutter_test.dart';
import 'package:quick_remote_pc/services/input/input_service.dart';
import 'package:quick_remote_pc/services/input_simulator.dart';
import 'package:quick_remote_pc/services/server/state_broadcaster.dart';

import 'fakes.dart';

void main() {
  late FakeInputService input;
  late StateBroadcaster broadcaster;
  late List<Map<String, dynamic>> sent;

  setUp(() {
    input = FakeInputService();
    InputSimulator.instance = input;
    sent = [];
    broadcaster = StateBroadcaster(onBroadcast: sent.add, hasClients: () => true);
  });

  Map<String, dynamic> track({int positionMs = 0, String? thumbnail = 'COVER'}) => {
        'hasMedia': true,
        'title': 'Song',
        'artist': 'Band',
        'positionMs': positionMs,
        'durationMs': 1000,
        'isPlaying': true,
        'thumbnail': thumbnail,
      };

  test('sends the cover once, then only state changes', () async {
    input.smtcState = track();
    await broadcaster.fetchAndBroadcastSmtcState();
    expect(sent.single['thumbnail'], 'COVER');

    await broadcaster.fetchAndBroadcastSmtcState(); // nothing changed
    expect(sent, hasLength(1));

    input.smtcState = track(positionMs: 2000);
    await broadcaster.fetchAndBroadcastSmtcState();
    expect(sent, hasLength(2));
    expect(sent.last.containsKey('thumbnail'), isFalse);
    expect(sent.last['positionMs'], 2000);
  });

  test('sends a changed or removed cover', () async {
    input.smtcState = track();
    await broadcaster.fetchAndBroadcastSmtcState();

    input.smtcState = track(thumbnail: 'OTHER');
    await broadcaster.fetchAndBroadcastSmtcState();
    expect(sent.last['thumbnail'], 'OTHER');

    input.smtcState = {'hasMedia': false};
    await broadcaster.fetchAndBroadcastSmtcState();
    expect(sent.last.containsKey('thumbnail'), isTrue);
    expect(sent.last['thumbnail'], isNull);
  });

  test('resendSmtcInFull repeats the whole state for a new client', () async {
    input.smtcState = track();
    await broadcaster.fetchAndBroadcastSmtcState();
    broadcaster.resendSmtcInFull();
    await broadcaster.fetchAndBroadcastSmtcState();
    expect(sent, hasLength(2));
    expect(sent.last['thumbnail'], 'COVER');
  });

  test('resendSlideState repeats an unchanged slide for a new client', () async {
    input.slideState = {'current': 3, 'total': 7, 'notes': 'Note', 'presenter': 'powerpoint'};
    await broadcaster.fetchAndBroadcastSlideState();
    await broadcaster.fetchAndBroadcastSlideState(); // nothing changed
    expect(sent, hasLength(1));

    broadcaster.resendSlideState();
    await broadcaster.fetchAndBroadcastSlideState();
    expect(sent, hasLength(2));
    expect(sent.last, containsPair('current', 3));
  });

  test('the slide state names the program running the show', () async {
    input.slideState = {'current': 2, 'total': 5, 'notes': '', 'presenter': 'wps'};
    await broadcaster.fetchAndBroadcastSlideState();
    expect(sent.single, containsPair('presenter', 'wps'));

    // The same slide in another program is news too.
    input.slideState = {'current': 2, 'total': 5, 'notes': '', 'presenter': 'impress'};
    await broadcaster.fetchAndBroadcastSlideState();
    expect(sent, hasLength(2));
    expect(sent.last, containsPair('presenter', 'impress'));
  });

  group('front and caps', () {
    const pdf = PresenterCaps(front: FrontWindow.pdf, caps: {RemoteCaps.laser});

    test('go with the slide state and make a change news', () async {
      input.slideState = {'current': 2, 'total': 5, 'notes': ''};
      input.caps = const PresenterCaps(front: FrontWindow.show, caps: {RemoteCaps.pen, RemoteCaps.goto});
      await broadcaster.fetchAndBroadcastSlideState();
      expect(sent.single, containsPair('front', 'show'));
      expect(sent.single, containsPair('caps', ['goto', 'pen']));

      await broadcaster.fetchAndBroadcastSlideState(); // nothing changed
      expect(sent, hasLength(1));

      // The same slide, the editor in front.
      input.caps = const PresenterCaps(front: FrontWindow.editor, caps: {RemoteCaps.pen, RemoteCaps.goto});
      await broadcaster.fetchAndBroadcastSlideState();
      expect(sent, hasLength(2));
      expect(sent.last, containsPair('front', 'editor'));
      expect(sent.last, containsPair('current', 2));
    });

    test('"not running" names the program in front, and a change of it is news', () async {
      input.slideState = {'error': 'POWERPOINT_NOT_RUNNING', 'presenter': 'wps'};
      await broadcaster.fetchAndBroadcastSlideState();
      expect(sent.map((m) => m['type']), ['STATUS', 'SLIDE_STATE']);
      expect(sent.first, containsPair('presenter', 'wps'));
      expect(sent.last, containsPair('presenter', 'wps'));

      await broadcaster.fetchAndBroadcastSlideState();
      expect(sent, hasLength(2), reason: 'unchanged');

      input.slideState = {'error': 'POWERPOINT_NOT_RUNNING', 'presenter': 'impress'};
      await broadcaster.fetchAndBroadcastSlideState();
      expect(sent, hasLength(3));
      expect(sent.last, containsPair('presenter', 'impress'));
    });

    test('go with "not running" too, which a new window in front repeats', () async {
      await broadcaster.fetchAndBroadcastSlideState();
      expect(sent.map((m) => m['type']), ['STATUS', 'SLIDE_STATE']);
      expect(sent.last, containsPair('caps', <String>[]));
      expect(sent.last.containsKey('front'), isFalse, reason: 'unknown (native Wayland)');

      input.caps = pdf;
      await broadcaster.fetchAndBroadcastSlideState();
      expect(sent, hasLength(3), reason: 'no second STATUS');
      expect(sent.last, containsPair('type', 'SLIDE_STATE'));
      expect(sent.last, containsPair('data', null));
      expect(sent.last, containsPair('front', 'pdf'));
    });

    test('a new window in front is noticed between the slide state reads', () async {
      broadcaster.startSlideStatePoller();
      addTearDown(broadcaster.stop);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(sent, hasLength(2)); // not running; the next 3 rounds skip the state
      input.caps = pdf;
      final deadline = DateTime.now().add(const Duration(seconds: 4));
      while (sent.length < 3 && DateTime.now().isBefore(deadline)) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
      expect(sent.last, containsPair('front', 'pdf'));
    });
  });
}
