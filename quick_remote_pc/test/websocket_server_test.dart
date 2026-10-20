import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:quick_remote_shared/quick_remote_shared.dart';
import 'package:quick_remote_pc/services/input/input_service.dart';
import 'package:quick_remote_pc/services/input/overlay_input_service.dart';
import 'package:quick_remote_pc/services/input_simulator.dart';
import 'package:quick_remote_pc/services/overlay/laser_overlay.dart';
import 'package:quick_remote_pc/services/websocket_server.dart';

import 'fakes.dart';

/// A client socket with every message it received, decoded.
class TestClient {
  TestClient(this.ws) {
    ws.listen(
      (data) => received.add(data is String ? jsonDecode(data) : data),
      onDone: () => closed.complete(ws.closeCode),
      onError: (_) {},
    );
  }

  final WebSocket ws;
  final List<dynamic> received = [];
  final Completer<int?> closed = Completer();

  void send(Map<String, dynamic> message) => ws.add(jsonEncode(message));
  void command(String command) => send({'command': command});

  Future<Map<String, dynamic>> next(String type) => eventually(
        () => received.whereType<Map<String, dynamic>>().where((m) => m['type'] == type).firstOrNull,
      );
}

/// Polls [read] until it returns non-null (or true), failing after 3 s.
Future<T> eventually<T extends Object>(T? Function() read) async {
  final deadline = DateTime.now().add(const Duration(seconds: 3));
  while (true) {
    final value = read();
    if (value != null && value != false) return value;
    if (DateTime.now().isAfter(deadline)) fail('condition not met within 3 s');
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}

/// Lets anything already in flight (or that should NOT happen) settle.
Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 150));

Uint8List moveFrame(int type, double dx, double dy) {
  final data = ByteData(9)
    ..setUint8(0, type)
    ..setFloat32(1, dx, Endian.little)
    ..setFloat32(5, dy, Endian.little);
  return data.buffer.asUint8List();
}

void main() {
  late FakeInputService input;
  late FakeMouse mouse;
  late WebSocketServer server;
  late String url;
  final clients = <TestClient>[];

  setUp(() async {
    input = FakeInputService();
    InputSimulator.instance = input;
    mouse = FakeMouse();
    server = WebSocketServer(mouseController: mouse, authTimeout: const Duration(milliseconds: 300));
    final http = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.serveForTesting(http);
    url = 'ws://127.0.0.1:${http.port}';
  });

  tearDown(() async {
    for (final c in clients) {
      await c.ws.close();
    }
    clients.clear();
    await server.stop();
  });

  Future<TestClient> connect({Map<String, dynamic>? headers}) async {
    final client = TestClient(await WebSocket.connect(url, headers: headers));
    clients.add(client);
    return client;
  }

  Future<TestClient> authed() async {
    final client = await connect();
    client.send({'auth': server.pin.value});
    final reply = await client.next('auth');
    expect(reply['status'], 'ok');
    return client;
  }

  group('handshake', () {
    test('refuses browsers (Origin header)', () async {
      await expectLater(
        WebSocket.connect(url, headers: {'Origin': 'https://example.com'}),
        throwsA(isA<WebSocketException>()),
      );
    });

    test('refuses a fourth unauthenticated socket from one address', () async {
      for (var i = 0; i < 3; i++) {
        await connect();
      }
      await expectLater(
        WebSocket.connect(url),
        throwsA(isA<WebSocketException>().having((e) => e.httpStatusCode, 'status', HttpStatus.tooManyRequests)),
      );
    });

    test('frees the pending slot once a client authenticates', () async {
      for (var i = 0; i < 3; i++) {
        await authed();
      }
      await connect(); // would be refused if the slots were still held
    });
  });

  group('auth', () {
    test('accepts the PIN and reports the presenter', () async {
      final client = await connect();
      client.send({'auth': server.pin.value});
      final reply = await client.next('auth');
      expect(reply, containsPair('status', 'ok'));
      expect(reply, containsPair('presenter', 'fake'));
      expect(reply, containsPair('presenters', ['fake', 'other']));
      expect(reply, containsPair('name', Platform.localHostname));
      expect(server.clientCount.value, 1);
    });

    test('rejects a wrong PIN and closes', () async {
      final client = await connect();
      client.send({'auth': '000000'});
      expect((await client.next('auth'))['status'], 'fail');
      expect(await client.closed.future, 4003);
      expect(server.clientCount.value, 0);
    });

    test('closes a client that does not authenticate in time', () async {
      final client = await connect();
      expect(await client.closed.future, 4001);
    });

    test('closes a client that sends a command before auth', () async {
      final client = await connect();
      client.command('NEXT');
      expect(await client.closed.future, 4002);
      expect(input.calls, isEmpty);
    });

    test('closes a client that sends a binary frame before auth', () async {
      final client = await connect();
      client.ws.add(moveFrame(0, 10, 10));
      expect(await client.closed.future, 4002);
      expect(mouse.moves, isEmpty);
    });

    test('closes on an oversized text message', () async {
      final client = await connect();
      client.ws.add('x' * 1025);
      expect(await client.closed.future, WebSocketStatus.messageTooBig);
    });
  });

  group('commands', () {
    test('executes an allowed command and acks it', () async {
      final client = await authed();
      client.command('NEXT');
      expect((await client.next('ack'))['command'], 'NEXT');
      expect(input.calls, contains('slideNext'));
    });

    test('ignores a command outside the allowlist', () async {
      final client = await authed();
      client.command('FORMAT_C');
      client.command('NEXT'); // acked after the rejected one is handled
      await client.next('ack');
      expect(client.received.where((m) => m is Map && m['command'] == 'FORMAT_C'), isEmpty);
    });

    test('passes a validated prefix argument', () async {
      final client = await authed();
      client.command('START_AT:5');
      await client.next('ack');
      expect(input.calls, contains('slideStartAt:5'));
    });

    test('drops a prefix argument that fails validation', () async {
      final client = await authed();
      client.command('START_AT:abc');
      client.command('VOLUME_SET:101');
      await settle();
      expect(input.calls.where((c) => c.startsWith('slideStartAt') || c.startsWith('setVolume')), isEmpty);
    });

    test('ignores slideshow-only commands without a slideshow', () async {
      final client = await authed();
      await client.next('STATUS'); // POWERPOINT_NOT_RUNNING from the fake
      client.command('MODE_PEN');
      client.command('ERASE_ALL');
      await settle();
      expect(input.calls, isNot(contains('modePen')));
      expect(input.calls, isNot(contains('eraseAllInk')));
    });

    test('runs slideshow-only commands during a slideshow', () async {
      input.slideState = {'current': 1, 'total': 3, 'notes': ''};
      final client = await authed();
      await client.next('SLIDE_STATE');
      client.command('MODE_PEN');
      await client.next('ack');
      expect(input.calls, contains('modePen'));
    });

    test('rechecks the slide state before dropping a slideshow-only command', () async {
      final client = await authed();
      await client.next('STATUS'); // not running; the poller would now wait
      input.slideState = {'current': 1, 'total': 3, 'notes': ''}; // started on the PC
      client.command('MODE_PEN');
      await client.next('ack');
      expect(input.calls, contains('modePen'));
    });

    test('releases a held mouse button when the client disconnects', () async {
      final client = await authed();
      client.command('LEFT_DOWN');
      await client.next('ack');
      await client.ws.close();
      await eventually(() => input.calls.contains('leftUp'));
    });

    test('drops commands beyond 30 per second, but never a button release', () async {
      final client = await authed();
      for (var i = 1; i <= 50; i++) {
        client.command('VOLUME_SET:$i');
      }
      client.command('LEFT_UP');
      await eventually(() => input.calls.contains('leftUp'));
      await settle();
      expect(input.calls.where((c) => c.startsWith('setVolume')).length, 30);
    });

    test('closes after three malformed messages', () async {
      final client = await authed();
      for (var i = 0; i < 3; i++) {
        client.ws.add('not json');
      }
      expect(await client.closed.future, 4004);
    });
  });

  group('move frames', () {
    test('moves the mouse for a valid TOUCH frame', () async {
      final client = await authed();
      client.ws.add(moveFrame(0, 12.5, -4));
      await eventually(() => mouse.moves.isNotEmpty);
      expect(mouse.moves.single, (12.5, -4.0));
    });

    test('TOUCH frames draw the stroke when the presenter draws it', () async {
      input.handlesDrawPointer = true;
      final client = await authed();
      client.command('LEFT_DOWN');
      await client.next('ack');
      client.ws.add(moveFrame(0, 12.5, -4));
      await eventually(() => input.calls.where((c) => c == 'drawPointerMoved').length == 2);
      // The start position before LEFT_DOWN, then the motion; the OS cursor stays.
      expect(input.calls.indexOf('drawPointerMoved'), lessThan(input.calls.indexOf('leftDown')));
      expect(mouse.moves, isEmpty);
    });

    test('ignores malformed frames', () async {
      final client = await authed();
      client.ws.add(moveFrame(0, 501, 0)); // over the per-frame limit
      client.ws.add(moveFrame(0, double.nan, 0));
      client.ws.add(moveFrame(2, 1, 1)); // unknown type
      client.ws.add(Uint8List(8)); // wrong length
      await settle();
      expect(mouse.moves, isEmpty);
    });

    test('ignores LASER frames without a slideshow', () async {
      final client = await authed();
      client.ws.add(moveFrame(1, 5, 5));
      await settle();
      expect(mouse.moves, isEmpty);
    });
  });

  group('laser overlay', () {
    late FakeLaserOverlay overlay;

    setUp(() {
      overlay = FakeLaserOverlay();
      InputSimulator.instance = OverlayInputService(input, overlay);
    });

    tearDown(() => LaserOverlaySettings.mode = LaserOverlayMode.auto);

    test('a changed Laser setting reaches the connected phones', () async {
      final client = await authed();
      LaserOverlaySettings.mode = LaserOverlayMode.never;
      expect(await client.next('OVERLAY'), containsPair('overlay', false));
      client.received.clear();
      LaserOverlaySettings.mode = LaserOverlayMode.always;
      expect(await client.next('OVERLAY'), containsPair('overlay', true));
      // Auto still lets the laser out of a show: nothing to tell.
      client.received.clear();
      LaserOverlaySettings.mode = LaserOverlayMode.auto;
      await settle();
      expect(client.received.whereType<Map>().where((m) => m['type'] == 'OVERLAY'), isEmpty);
    });

    test('the auth reply says the laser works outside a show', () async {
      final client = await connect();
      client.send({'auth': server.pin.value});
      expect(await client.next('auth'), containsPair('overlay', true));
    });

    test('a PC without the overlay says so', () async {
      final client = await connect();
      InputSimulator.instance = input;
      client.send({'auth': server.pin.value});
      expect(await client.next('auth'), containsPair('overlay', false));
    });

    test('draws the laser without a slideshow, the cursor stays still', () async {
      final client = await authed();
      await client.next('STATUS'); // not running
      client.command('MODE_LASER');
      await client.next('ack');
      client.ws.add(moveFrame(1, 5, 5));
      await eventually(() => overlay.calls.contains('move'));
      client.command('LASER_OFF');
      client.command('MODE_ARROW');
      await eventually(() => overlay.calls.contains('hide'));
      expect(mouse.moves, isEmpty);
      // The program's keys would go to whatever window has the focus.
      expect(input.calls, isNot(contains('modeArrow')));
    });

    test('the pen draws on the overlay without a slideshow, nothing is clicked', () async {
      final client = await authed();
      await client.next('STATUS');
      client.command('MODE_PEN');
      await client.next('ack');
      client.command('LEFT_DOWN');
      client.ws.add(moveFrame(0, 5, 5));
      client.command('LEFT_UP');
      await eventually(() => overlay.calls.contains('inkEnd'));
      expect(overlay.calls, containsAllInOrder(['inkBegin:pen:ff0000', 'inkTo', 'inkEnd']));
      expect(input.calls, isNot(anyOf(contains('leftDown'), contains('modePen'))));
      expect(mouse.moves, isEmpty);
    });

    test('without a slideshow the overlay covers the screen in black', () async {
      final client = await authed();
      await client.next('STATUS');
      client.command('BLACK_SCREEN');
      await eventually(() => overlay.calls.contains('blank:000000'));
      // No B typed into whatever window has the focus.
      expect(input.calls, isNot(contains('blackScreen')));
    });

    test('a phone that leaves mid-laser puts it away', () async {
      final client = await authed();
      await client.next('STATUS');
      client.command('MODE_LASER');
      await client.next('ack');
      await client.ws.close();
      await eventually(() => overlay.calls.contains('hide'));
    });
  });

  group('two phones', () {
    Future<(TestClient, TestClient)> twoInAShow() async {
      input.slideState = {'current': 1, 'total': 3, 'notes': ''};
      final a = await authed();
      await a.next('SLIDE_STATE');
      final b = await authed();
      return (a, b);
    }

    int count(String call) => input.calls.where((c) => c == call).length;

    test('each phone\'s own "keep the ink" goes with its slide commands', () async {
      final (a, b) = await twoInAShow();
      final c = await authed(); // never sent SET_KEEP_INK
      a.command(RemoteCommands.keepInk(true));
      b.command(RemoteCommands.keepInk(false));
      await a.next('ack');
      await b.next('ack');
      a.command(RemoteCommands.next);
      await eventually(() => input.inkChoices.isNotEmpty);
      b.command(RemoteCommands.prev);
      await eventually(() => input.inkChoices.length == 2);
      c.command(RemoteCommands.startAt(2));
      await eventually(() => input.inkChoices.length == 3);
      expect(input.inkChoices, ['slideNext:keep', 'slidePrev:clear', 'slideStartAt:2:clear']);
    });

    test('the second phone does not end the first one\'s laser', () async {
      final (a, b) = await twoInAShow();
      a.command('MODE_LASER');
      await a.next('ack');

      // B's whole gesture is dropped, and B is told why.
      b.command('MODE_PEN');
      b.ws.add(moveFrame(0, 5, 5));
      b.command('LEFT_DOWN');
      b.command('LEFT_UP');
      b.command('MODE_ARROW');
      final busy = await b.next('STATUS');
      expect(busy['state'], 'COMMAND_FAILED');
      expect(busy['code'], 'POINTER_BUSY');
      expect(busy['detail'], isNotEmpty, reason: 'phones without error codes show it');
      await settle();
      expect(input.calls, isNot(contains('modePen')));
      expect(input.calls, isNot(contains('modeArrow')));
      expect(mouse.moves, isEmpty);

      // A's gesture goes on and ends; then B may draw.
      a.ws.add(moveFrame(0, 3, 0));
      a.command('MODE_ARROW');
      await eventually(() => input.calls.contains('modeArrow'));
      expect(mouse.moves, [(3.0, 0.0)]);
      b.command('MODE_PEN');
      await eventually(() => input.calls.contains('modePen'));
    });

    test('slide commands still work while another phone points', () async {
      final (a, b) = await twoInAShow();
      a.command('MODE_LASER');
      await a.next('ack');
      b.command('NEXT');
      await eventually(() => input.calls.contains('slideNext'));
    });

    test('a phone that leaves mid-gesture frees the pointer', () async {
      final (a, b) = await twoInAShow();
      a.command('MODE_LASER');
      await a.next('ack');
      await a.ws.close();
      await eventually(() => input.calls.contains('modeArrow'));
      b.command('MODE_PEN');
      await eventually(() => input.calls.contains('modePen'));
    });

    test('two phones pressing NEXT at once advance one slide', () async {
      final (a, b) = await twoInAShow();
      a.command('NEXT');
      b.command('NEXT');
      await b.next('ack');
      await a.next('ack');
      await settle();
      expect(count('slideNext'), 1);
    });

    test('one phone pressing twice advances twice', () async {
      final (a, _) = await twoInAShow();
      a.command('NEXT');
      a.command('NEXT');
      await eventually(() => count('slideNext') == 2);
    });

    test('a second press after the window counts', () async {
      final (a, b) = await twoInAShow();
      a.command('NEXT');
      await eventually(() => count('slideNext') == 1);
      await Future<void>.delayed(const Duration(milliseconds: 350));
      b.command('NEXT');
      await eventually(() => count('slideNext') == 2);
    });
  });

  group('slide previews', () {
    SlideImage picture(int index, int width) =>
        (jpeg: Uint8List.fromList([0xFF, 0xD8, index, 0xFF, 0xD9]), width: width, height: width * 9 ~/ 16);

    List<SlideImageFrame> frames(TestClient c) =>
        c.received.whereType<Uint8List>().map(SlideImageFrame.decode).nonNulls.toList();

    Future<TestClient> inAShow() async {
      input.slideState = {'current': 2, 'total': 5, 'notes': '', 'deckKey': 'talk.pptx'};
      input.exporter = picture;
      final client = await authed();
      await client.next('SLIDE_STATE');
      return client;
    }

    test('the slide state carries front and caps', () async {
      input.caps = const PresenterCaps(front: FrontWindow.show, caps: {RemoteCaps.previews, RemoteCaps.goto});
      final client = await inAShow();
      final state = client.received.whereType<Map<String, dynamic>>().firstWhere((m) => m['type'] == 'SLIDE_STATE');
      expect(state, containsPair('front', 'show'));
      expect(state, containsPair('caps', ['goto', 'previews']));
    });

    test('the auth reply and the slide state announce them', () async {
      final client = await connect();
      input.slideState = {'current': 2, 'total': 5, 'notes': '', 'deckKey': 'talk.pptx'};
      client.send({'auth': server.pin.value});
      expect(await client.next('auth'), containsPair('previews', true));
      expect((await client.next('SLIDE_STATE'))['deck'], SlideImageFrame.deckId('talk.pptx|5'));
    });

    test('a phone that did not turn them on gets no binary frame', () async {
      final client = await inAShow();
      client.command(RemoteCommands.slideThumb(1));
      server.triggerSlideStateUpdate();
      await settle();
      expect(client.received.whereType<List<int>>(), isEmpty);
      expect(input.exports, isEmpty);
    });

    test('turned on, the current and the next slide arrive', () async {
      final client = await inAShow();
      client.command(RemoteCommands.slidePreview(true));
      final got = await eventually(() => frames(client).length == 2 ? frames(client) : null);
      expect(got.map((f) => (f.kind, f.slide, f.width)), [
        (SlideImageKind.current, 2, 1280),
        (SlideImageKind.next, 3, 640),
      ]);
      expect(got.first.deck, SlideImageFrame.deckId('talk.pptx|5'));

      // A changed slide sends the new pair, once.
      input.slideState = {'current': 3, 'total': 5, 'notes': '', 'deckKey': 'talk.pptx'};
      server.triggerSlideStateUpdate();
      await eventually(() => frames(client).length == 4);
      server.triggerSlideStateUpdate();
      await settle();
      expect(frames(client).skip(2).map((f) => (f.kind, f.slide)), [
        (SlideImageKind.current, 3),
        (SlideImageKind.next, 4),
      ]);
    });

    test('SLIDE_THUMB answers with that slide\'s thumbnail', () async {
      final client = await inAShow();
      client.command(RemoteCommands.slidePreview(true));
      await eventually(() => frames(client).length == 2);
      client.command(RemoteCommands.slideThumb(4));
      client.command(RemoteCommands.slideThumb(9)); // past the end: nothing
      final thumb = await eventually(
        () => frames(client).where((f) => f.kind == SlideImageKind.thumbnail).firstOrNull,
      );
      expect((thumb.slide, thumb.width, thumb.jpeg[2]), (4, 320, 4));
      await settle();
      expect(frames(client).where((f) => f.kind == SlideImageKind.thumbnail), hasLength(1));
    });

    test('a quick run of slide changes sends only the last slide', () async {
      final client = await inAShow();
      final gate = Completer<void>();
      input.exportGate = gate.future;
      client.command(RemoteCommands.slidePreview(true));
      await eventually(() => input.exports.isNotEmpty); // slide 2, held
      for (final slide in [3, 4]) {
        input.slideState = {'current': slide, 'total': 5, 'notes': '', 'deckKey': 'talk.pptx'};
        await server.refreshSlideStateForTesting();
      }
      input.exportGate = null;
      gate.complete();
      await eventually(() => frames(client).length == 2);
      await settle();
      expect(frames(client).map((f) => (f.kind, f.slide)), [
        (SlideImageKind.current, 4),
        (SlideImageKind.next, 5),
      ]);
      expect(input.exports.map((e) => e.$1), [2, 4, 5]);
    });

    test('turned off, nothing more arrives', () async {
      final client = await inAShow();
      client.command(RemoteCommands.slidePreview(true));
      await eventually(() => frames(client).length == 2);
      client.command(RemoteCommands.slidePreview(false));
      await eventually(() => client.received.any((m) => m is Map && m['command'] == 'SLIDE_PREVIEW:0'));
      input.slideState = {'current': 3, 'total': 5, 'notes': '', 'deckKey': 'talk.pptx'};
      server.triggerSlideStateUpdate();
      await settle();
      expect(frames(client), hasLength(2));
    });
  });

  group('phone names', () {
    test('keeps ordinary names, including non-ASCII', () {
      expect(ConnectedClient.sanitizeName('Ayşe\'nin Telefonu'), 'Ayşe\'nin Telefonu');
    });

    test('drops non-strings and names with nothing visible', () {
      expect(ConnectedClient.sanitizeName(42), isNull);
      expect(ConnectedClient.sanitizeName(' \u200B\t '), isNull);
    });

    test('shortens long names', () {
      final name = ConnectedClient.sanitizeName('x' * 100)!;
      expect(name.runes.length, ConnectedClient.maxNameLength);
      expect(name, endsWith('…'));
    });
  });

  group('connected clients', () {
    test('lists authenticated phones and marks the server as paired', () async {
      expect(server.pairedOnce.value, isFalse);
      await connect(); // not authenticated: not listed
      await authed();
      expect(server.connectedClients.value, hasLength(1));
      expect(server.connectedClients.value.single.address, '127.0.0.1');
      expect(server.pairedOnce.value, isTrue);
    });

    test('kicking closes that phone with 4005 and replaces the PIN', () async {
      final kicked = await authed();
      final other = await authed();
      final oldPin = server.pin.value;

      server.kickClient(server.connectedClients.value.first.id);

      expect(await kicked.closed.future, WebSocketServer.closedByPc);
      expect(server.pin.value, isNot(oldPin));
      expect(server.connectedClients.value, hasLength(1));
      other.command('NEXT');
      await other.next('ack'); // still connected
    });

    test('shows the name a phone sends with its PIN', () async {
      final named = await connect();
      named.send({'auth': server.pin.value, 'name': 'Berat\u202Es Galaxy\n A52'});
      expect((await named.next('auth'))['status'], 'ok');
      await authed(); // an older app sends no name
      final names = server.connectedClients.value.map((c) => c.name).toList();
      expect(names, ['Berats Galaxy A52', null]);
    });

    test('stop forgets the pairing', () async {
      await authed();
      await server.stop();
      expect(server.pairedOnce.value, isFalse);
      expect(server.connectedClients.value, isEmpty);
    });
  });

  test('stop releases a held button and disconnects clients', () async {
    final client = await authed();
    client.command('LEFT_DOWN');
    await client.next('ack');
    await server.stop();
    expect(input.calls, contains('leftUp'));
    await client.closed.future.timeout(const Duration(seconds: 3));
  });
}
