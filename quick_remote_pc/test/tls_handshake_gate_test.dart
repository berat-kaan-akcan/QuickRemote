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
    int maxStartsPerClient = 20,
    int maxStartsTotal = 100,
    Duration startWindow = const Duration(seconds: 10),
    bool Function(InternetAddress)? accepts,
    String Function(InternetAddress)? clientKey,
  }) =>
      TlsHandshakeGate.bind(
        InternetAddress.loopbackIPv4,
        0,
        context,
        handshakeTimeout: handshakeTimeout,
        maxPerClient: maxPerClient,
        maxTotal: maxTotal,
        accepts: accepts ?? (_) => true,
        clientKey: clientKey ?? (a) => a.address,
        maxStartsPerClient: maxStartsPerClient,
        maxStartsTotal: maxStartsTotal,
        startWindow: startWindow,
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

  test('refuses new connections beyond the per-client rate', () async {
    final gate = await bind(maxStartsPerClient: 2);
    final server = HttpServer.listenOn(gate);

    // Two connections dropped at once still count.
    for (var i = 0; i < 2; i++) {
      final s = await Socket.connect(InternetAddress.loopbackIPv4, gate.port);
      while (gate.handshakesInProgress < 1) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      s.destroy();
      while (gate.handshakesInProgress > 0) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
    }
    final third = await Socket.connect(InternetAddress.loopbackIPv4, gate.port);
    await closedByPeer(third).timeout(const Duration(seconds: 5));
    expect(gate.handshakesInProgress, 0);

    third.destroy();
    await server.close(force: true);
    await gate.close();
  });

  /// Opens a connection and drops it once the gate has counted it.
  Future<void> openAndDrop(TlsHandshakeGate gate) async {
    final s = await Socket.connect(InternetAddress.loopbackIPv4, gate.port);
    while (gate.handshakesInProgress < 1) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    s.destroy();
    while (gate.handshakesInProgress > 0) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
  }

  test('takes new connections again once the window has passed', () async {
    final gate = await bind(maxStartsPerClient: 1, startWindow: const Duration(milliseconds: 300));
    final server = HttpServer.listenOn(gate);
    server.listen((request) => request.response.close());

    await openAndDrop(gate);
    final refused = await Socket.connect(InternetAddress.loopbackIPv4, gate.port);
    await closedByPeer(refused).timeout(const Duration(seconds: 5));
    refused.destroy();

    // A refused connection does not count: the window is not pushed on.
    await Future<void>.delayed(const Duration(milliseconds: 350));
    final client = trustingClient();
    final response = await (await client.getUrl(Uri.parse('https://127.0.0.1:${gate.port}/'))).close();
    expect(response.statusCode, 200);

    client.close(force: true);
    await server.close(force: true);
    await gate.close();
  });

  test('refuses new connections beyond the total rate, whoever they come from', () async {
    var n = 0;
    // Every connection counts as another client.
    final gate = await bind(maxStartsTotal: 3, clientKey: (_) => 'client-${n++}');
    final server = HttpServer.listenOn(gate);

    for (var i = 0; i < 3; i++) {
      await openAndDrop(gate);
    }
    final fourth = await Socket.connect(InternetAddress.loopbackIPv4, gate.port);
    await closedByPeer(fourth).timeout(const Duration(seconds: 5));
    expect(gate.trackedClients, 3);

    fourth.destroy();
    await server.close(force: true);
    await gate.close();
  });

  test('forgets clients once their window has passed', () async {
    var n = 0;
    final gate = await bind(
      maxStartsTotal: 4,
      startWindow: const Duration(milliseconds: 200),
      clientKey: (_) => 'client-${n++}',
    );
    final server = HttpServer.listenOn(gate);

    // Many more clients than the total allows, over several windows: the
    // table never holds more than the total plus the one being added.
    for (var round = 0; round < 4; round++) {
      for (var i = 0; i < 4; i++) {
        await openAndDrop(gate);
        expect(gate.trackedClients, lessThanOrEqualTo(5));
      }
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
    expect(n, greaterThanOrEqualTo(16));

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
