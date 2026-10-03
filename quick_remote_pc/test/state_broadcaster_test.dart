import 'package:flutter_test/flutter_test.dart';
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
}
