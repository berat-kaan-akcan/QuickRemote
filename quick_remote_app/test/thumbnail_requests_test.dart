import 'package:flutter_test/flutter_test.dart';
import 'package:quick_remote_app/services/websocket/thumbnail_requests.dart';

void main() {
  late List<int> sent;
  late int failures;
  late ThumbnailRequests requests;

  ThumbnailRequests make({int max = 4}) => ThumbnailRequests(
        send: sent.add,
        onFailed: () => failures++,
        maxInFlight: max,
      );

  setUp(() {
    sent = [];
    failures = 0;
    requests = make();
  });

  testWidgets('sends at most four at once, in the order asked', (tester) async {
    for (var i = 1; i <= 7; i++) {
      requests.request(i);
    }
    expect(sent, [1, 2, 3, 4]);
    requests.arrived(2);
    expect(sent, [1, 2, 3, 4, 5]);
    requests.arrived(1);
    requests.arrived(3);
    expect(sent, [1, 2, 3, 4, 5, 6, 7]);
    requests.reset();
  });

  testWidgets('a slide already asked is not asked twice', (tester) async {
    requests.request(1);
    requests.request(1);
    for (var i = 2; i <= 6; i++) {
      requests.request(i);
    }
    requests.request(5); // waiting
    expect(sent, [1, 2, 3, 4]);
    requests.arrived(1);
    expect(sent, [1, 2, 3, 4, 5]);
    requests.reset();
  });

  testWidgets('cancel takes back a waiting request, not one in flight',
      (tester) async {
    for (var i = 1; i <= 6; i++) {
      requests.request(i);
    }
    requests.cancel(5);
    requests.cancel(1); // already sent: no effect, it still comes
    requests.arrived(1);
    expect(sent, [1, 2, 3, 4, 6]);
    // 5 may be asked for again after a cancel.
    requests.request(5);
    requests.arrived(2);
    expect(sent.last, 5);
    requests.reset();
  });

  testWidgets('an unanswered request fails after the timeout and frees a slot',
      (tester) async {
    for (var i = 1; i <= 5; i++) {
      requests.request(i);
    }
    await tester.pump(const Duration(seconds: 3, milliseconds: 900));
    expect(failures, 0);
    expect(sent, [1, 2, 3, 4]);
    await tester.pump(const Duration(milliseconds: 200));
    expect(failures, 4);
    for (var i = 1; i <= 4; i++) {
      expect(requests.failed(i), isTrue);
    }
    expect(requests.failed(5), isFalse);
    expect(sent, [1, 2, 3, 4, 5], reason: 'the queue moves on after a failure');
    requests.reset();
  });

  testWidgets('a failed slide is not asked for again until reset',
      (tester) async {
    requests.request(1);
    await tester.pump(const Duration(seconds: 5));
    expect(requests.failed(1), isTrue);
    requests.request(1);
    expect(sent, [1]);
    requests.reset();
    expect(requests.failed(1), isFalse);
    requests.request(1);
    expect(sent, [1, 1]);
    requests.reset();
  });

  testWidgets('an arrival cancels the timeout', (tester) async {
    requests.request(1);
    requests.arrived(1);
    await tester.pump(const Duration(seconds: 10));
    expect(failures, 0);
    expect(requests.failed(1), isFalse);
  });

  testWidgets('arrived for an unknown slide only pumps the queue',
      (tester) async {
    requests.arrived(99);
    expect(sent, isEmpty);
    expect(failures, 0);
  });

  testWidgets('reset drops queued and in-flight work and their timers',
      (tester) async {
    for (var i = 1; i <= 6; i++) {
      requests.request(i);
    }
    requests.reset();
    await tester.pump(const Duration(seconds: 10));
    expect(failures, 0);
    expect(sent, [1, 2, 3, 4], reason: '5 and 6 were forgotten');
    requests.arrived(1); // a late answer of the old deck is harmless
    expect(sent, [1, 2, 3, 4]);
  });

  testWidgets('maxInFlight of 1 is strictly sequential', (tester) async {
    requests = make(max: 1);
    requests.request(1);
    requests.request(2);
    expect(sent, [1]);
    requests.arrived(1);
    expect(sent, [1, 2]);
    requests.reset();
  });

  testWidgets('works without an onFailed callback', (tester) async {
    final r = ThumbnailRequests(send: sent.add);
    r.request(1);
    await tester.pump(const Duration(seconds: 5));
    expect(r.failed(1), isTrue);
  });
}
