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
    // An empty config: some openssl builds on Windows (Strawberry Perl's)
    // look for one at a path baked in at build time and fail without it.
    final config = File('${dir.path}/openssl.cnf')..writeAsStringSync('');
    final result = await Process.run(
      'openssl',
      [
        'req', '-x509', '-newkey', 'rsa:2048', '-nodes',
        '-keyout', '${dir.path}/key.pem', '-out', '${dir.path}/cert.pem',
        '-days', '1', '-subj', '/CN=QuickRemoteTest',
      ],
      environment: {'OPENSSL_CONF': config.path},
    );
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
    Duration requestTimeout = const Duration(seconds: 10),
    int maxHeaderBytes = 16 * 1024,
    int maxAwaitingPerClient = 16,
    int maxAwaitingTotal = 128,
    bool Function(InternetAddress)? accepts,
  }) =>
      TlsHandshakeGate.bind(
        InternetAddress.loopbackIPv4,
        0,
        context,
        handshakeTimeout: handshakeTimeout,
        maxPerClient: maxPerClient,
        maxTotal: maxTotal,
        requestTimeout: requestTimeout,
        maxHeaderBytes: maxHeaderBytes,
        maxAwaitingPerClient: maxAwaitingPerClient,
        maxAwaitingTotal: maxAwaitingTotal,
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

  // After the handshake the HTTP request has to follow: dart:io's HttpServer
  // times out a silent connection only after 120 s and the handshake slot is
  // free by then, so an address could hold file descriptors without limit.
  group('after the handshake', () {
    Future<SecureSocket> tlsSocket(TlsHandshakeGate gate) =>
        SecureSocket.connect(InternetAddress.loopbackIPv4, gate.port, onBadCertificate: (_) => true);

    test('closes a connection that sends no request in time', () async {
      final gate = await bind(requestTimeout: const Duration(milliseconds: 300));
      final server = HttpServer.listenOn(gate);

      final socket = await tlsSocket(gate);
      await closedByPeer(socket).timeout(const Duration(seconds: 5));
      expect(gate.awaitingRequest, 0);

      socket.destroy();
      await server.close(force: true);
      await gate.close();
    });

    test('closes a connection whose request head never ends', () async {
      final gate = await bind(maxHeaderBytes: 4096);
      final server = HttpServer.listenOn(gate);

      final socket = await tlsSocket(gate);
      final closed = closedByPeer(socket);
      socket.write('GET / HTTP/1.1\r\nHost: x\r\nX-A: ${'a' * 6000}');
      await closed.timeout(const Duration(seconds: 5));
      expect(gate.awaitingRequest, 0);

      socket.destroy();
      await server.close(force: true);
      await gate.close();
    });

    test('finds the end of the head across chunks and keeps serving', () async {
      final gate = await bind(requestTimeout: const Duration(milliseconds: 600));
      final server = HttpServer.listenOn(gate);
      server.listen((request) => request.response
        ..write('ok')
        ..close());

      final socket = await tlsSocket(gate);
      final text = StringBuffer();
      socket.listen((d) => text.write(utf8.decode(d, allowMalformed: true)), onError: (_) {});
      socket.write('GET / HTTP/1.1\r\nHost: x\r\n\r');
      await socket.flush();
      await Future<void>.delayed(const Duration(milliseconds: 100));
      socket.write('\n');
      await socket.flush();
      // Longer than requestTimeout: the head was complete, so no deadline.
      await Future<void>.delayed(const Duration(milliseconds: 900));
      expect(text.toString(), contains('200 OK'));
      expect(gate.awaitingRequest, 0);

      socket.destroy();
      await server.close(force: true);
      await gate.close();
    });

    test('refuses more waiting connections than the per-client limit', () async {
      final gate = await bind(maxAwaitingPerClient: 2);
      final server = HttpServer.listenOn(gate);

      final waiting = [for (var i = 0; i < 2; i++) await tlsSocket(gate)];
      while (gate.awaitingRequest < 2) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      final third = await tlsSocket(gate);
      await closedByPeer(third).timeout(const Duration(seconds: 5));
      expect(gate.awaitingRequest, 2);

      for (final s in waiting) {
        s.destroy();
      }
      while (gate.awaitingRequest > 0) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      third.destroy();
      await server.close(force: true);
      await gate.close();
    });
  });
}
