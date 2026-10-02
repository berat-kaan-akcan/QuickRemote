import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:quick_remote_pc/services/server/pre_auth_byte_limit.dart';

void main() {
  late HttpServer server;
  late StreamController<(WebSocket, PreAuthByteLimit)> accepted;

  setUp(() async {
    accepted = StreamController();
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      accepted.add(await PreAuthByteLimit.upgrade(request, budget: 256, maxFramePayload: 128));
    });
  });

  tearDown(() async {
    await server.close(force: true);
    await accepted.close();
  });

  Future<WebSocket> connect() => WebSocket.connect('ws://127.0.0.1:${server.port}');

  test('delivers messages and negotiates no compression', () async {
    final client = await connect();
    final (ws, _) = await accepted.stream.first;
    final received = ws.first;
    client.add('{"auth":"123456"}');
    expect(await received, '{"auth":"123456"}');
    expect(client.extensions, isEmpty);
    await client.close();
  });

  test('closes an unauthenticated client that sends more than the budget', () async {
    final client = await connect();
    final (ws, _) = await accepted.stream.first;
    final messages = <dynamic>[];
    final done = ws.listen(messages.add).asFuture<void>();
    for (var i = 0; i < 10; i++) {
      client.add('x' * 100);
    }
    await done.timeout(const Duration(seconds: 5));
    expect(messages.length, lessThan(3));
    await client.close();
  });

  test('stops counting once lifted', () async {
    final client = await connect();
    final (ws, limit) = await accepted.stream.first;
    limit.lift();
    final received = ws.take(10).length;
    for (var i = 0; i < 10; i++) {
      client.add('x' * 100);
    }
    expect(await received.timeout(const Duration(seconds: 5)), 10);
    await client.close();
  });

  test('rejects a frame larger than maxFramePayload', () async {
    final client = await connect();
    final (ws, limit) = await accepted.stream.first;
    limit.lift();
    final messages = <dynamic>[];
    final done = ws.listen(messages.add, onError: (_) {}).asFuture<void>();
    client.add('x' * 200);
    await done.timeout(const Duration(seconds: 5));
    expect(messages, isEmpty);
    await client.close();
  });

  test('cuts off an endless fragmented message', () async {
    final socket = await Socket.connect(InternetAddress.loopbackIPv4, server.port);
    final key = base64.encode(List.filled(16, 1));
    socket.write('GET / HTTP/1.1\r\n'
        'Host: 127.0.0.1\r\n'
        'Upgrade: websocket\r\n'
        'Connection: Upgrade\r\n'
        'Sec-WebSocket-Key: $key\r\n'
        'Sec-WebSocket-Version: 13\r\n\r\n');
    final closed = Completer<void>();
    socket.listen((_) {}, onDone: closed.complete, onError: (_) {
      if (!closed.isCompleted) closed.complete();
    });
    final (ws, _) = await accepted.stream.first;
    final messages = <dynamic>[];
    ws.listen(messages.add, onError: (_) {});

    // A text frame without FIN, then 100-byte continuation frames, none final.
    // Each frame is under maxFramePayload; only the byte budget stops them.
    Uint8List frame(int opcode) => Uint8List.fromList([opcode, 0x80 | 100, 0, 0, 0, 0, ...List.filled(100, 0x61)]);
    socket.add(frame(0x1));
    for (var i = 0; i < 20 && !closed.isCompleted; i++) {
      socket.add(frame(0x0));
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    await closed.future.timeout(const Duration(seconds: 5));
    expect(messages, isEmpty);
    socket.destroy();
  });
}
