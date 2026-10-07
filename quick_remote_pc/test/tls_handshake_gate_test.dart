import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quick_remote_pc/services/server/tls_handshake_gate.dart';

void main() {
  late Directory dir;
  late SecurityContext context;

  setUpAll(() async {
    dir = await Directory.systemTemp.createTemp('qr_tls_gate');
    final result = await Process.run('openssl', [
      'req', '-x509', '-newkey', 'rsa:2048', '-nodes',
      '-keyout', '${dir.path}/key.pem', '-out', '${dir.path}/cert.pem',
      '-days', '1', '-subj', '/CN=QuickRemoteTest',
    ]);
    expect(result.exitCode, 0, reason: '${result.stderr}');
    context = SecurityContext()
      ..useCertificateChain('${dir.path}/cert.pem')
      ..usePrivateKey('${dir.path}/key.pem');
  });

  tearDownAll(() => dir.delete(recursive: true));

  Future<TlsHandshakeGate> bind({
    Duration handshakeTimeout = const Duration(seconds: 10),
    int maxPerClient = 8,
    int maxTotal = 64,
    bool Function(InternetAddress)? accepts,
  }) =>
      TlsHandshakeGate.bind(
        InternetAddress.loopbackIPv4,
        0,
        context,
        handshakeTimeout: handshakeTimeout,
        maxPerClient: maxPerClient,
        maxTotal: maxTotal,
        accepts: accepts ?? (_) => true,
        clientKey: (a) => a.address,
      );

  HttpClient trustingClient() => HttpClient()..badCertificateCallback = (_, _, _) => true;

  /// Completes when the peer closes [socket].
  Future<void> closedByPeer(Socket socket) {
    final closed = Completer<void>();
    socket.listen((_) {}, onDone: closed.complete, onError: (_) {
      if (!closed.isCompleted) closed.complete();
    });
    return closed.future;
  }

  test('serves HTTP over TLS, large responses included', () async {
    final gate = await bind();
    final server = HttpServer.listenOn(gate);
    final body = 'x' * (1024 * 1024);
    server.listen((request) => request.response
      ..write(body)
      ..close());

    final client = trustingClient();
    final response = await (await client.getUrl(Uri.parse('https://127.0.0.1:${gate.port}/'))).close();
    expect(await response.transform(utf8.decoder).join(), body);

    client.close(force: true);
    await server.close(force: true);
    await gate.close();
  });

  test('carries a WebSocket both ways', () async {
    final gate = await bind();
    final server = HttpServer.listenOn(gate);
    server.listen((request) async {
      final ws = await WebSocketTransformer.upgrade(request);
      ws.listen((message) => ws.add('echo $message'));
    });

    final ws = await WebSocket.connect('wss://127.0.0.1:${gate.port}', customClient: trustingClient());
    final replies = ws.take(2).toList();
    ws.add('one');
    ws.add('two');
    expect(await replies.timeout(const Duration(seconds: 5)), ['echo one', 'echo two']);

    await ws.close();
    await server.close(force: true);
    await gate.close();
  });

  test('closes a connection that never completes its handshake', () async {
    final gate = await bind(handshakeTimeout: const Duration(milliseconds: 200));
    final server = HttpServer.listenOn(gate);

    final socket = await Socket.connect(InternetAddress.loopbackIPv4, gate.port);
    await closedByPeer(socket).timeout(const Duration(seconds: 5));
    expect(gate.handshakesInProgress, 0);

    socket.destroy();
    await server.close(force: true);
    await gate.close();
  });

  test('refuses handshakes beyond the per-client limit', () async {
    final gate = await bind(maxPerClient: 2);
    final server = HttpServer.listenOn(gate);

    final stalled = [
      for (var i = 0; i < 2; i++) await Socket.connect(InternetAddress.loopbackIPv4, gate.port),
    ];
    // Let the gate take both before the third arrives.
    while (gate.handshakesInProgress < 2) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    final third = await Socket.connect(InternetAddress.loopbackIPv4, gate.port);
    await closedByPeer(third).timeout(const Duration(seconds: 5));
    expect(gate.handshakesInProgress, 2);

    // A finished handshake frees its slot.
    for (final s in stalled) {
      s.destroy();
    }
    while (gate.handshakesInProgress > 0) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    third.destroy();
    await server.close(force: true);
    await gate.close();
  });

  test('closes connections from addresses it does not accept', () async {
    final gate = await bind(accepts: (_) => false);
    final server = HttpServer.listenOn(gate);

    final socket = await Socket.connect(InternetAddress.loopbackIPv4, gate.port);
    await closedByPeer(socket).timeout(const Duration(seconds: 5));
    expect(gate.handshakesInProgress, 0);

    socket.destroy();
    await server.close(force: true);
    await gate.close();
  });
}
