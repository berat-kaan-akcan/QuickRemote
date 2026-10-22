import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quick_remote_app/services/websocket/websocket_client.dart';
import 'package:quick_remote_app/services/websocket_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The parts of the client that need no TLS server: input checks, a refused
/// connection, and that disconnect leaves nothing behind. Loopback only.
void main() {
  late List<AppConnectionState> states;
  late List<Object?> authResults;
  late WebSocketClient client;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    states = [];
    authResults = [];
    client = WebSocketClient(
      onConnectionStateChanged: states.add,
      onMessage: (_) {},
      onImage: (_) {},
      onAuthResolved: authResults.add,
    );
  });

  Future<int> closedPort() async {
    final s = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final port = s.port;
    await s.close();
    return port;
  }

  test('starts disconnected with nothing to reconnect to', () {
    expect(client.isConnected, isFalse);
    expect(client.connectionState, AppConnectionState.disconnected);
    expect(client.host, isNull);
    expect(client.port, isNull);
  });

  test('an empty or missing PIN is refused before any state change', () async {
    for (final pin in [null, '']) {
      final r = await client.connect('127.0.0.1', 1, pin: pin);
      expect(r.success, isFalse);
      expect(r.error, ConnectionError.pinEmpty);
    }
    expect(states, isEmpty);
    expect(client.host, isNull, reason: 'a refused attempt is not remembered');
  });

  test('a refused connection reports serverNotFound and ends disconnected',
      () async {
    final port = await closedPort();
    final r = await client.connect('127.0.0.1', port, pin: '123456');
    expect(r.success, isFalse);
    expect(r.error, ConnectionError.serverNotFound);
    expect(states, [
      AppConnectionState.connecting,
      AppConnectionState.disconnected,
    ]);
    expect(client.host, '127.0.0.1');
    expect(client.port, port);
    expect(client.serverAddress, '127.0.0.1:$port');
    expect(client.isConnected, isFalse);
  });

  test('a failed first attempt starts no reconnect loop', () async {
    final port = await closedPort();
    await client.connect('127.0.0.1', port, pin: '123456');
    states.clear();
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(states, isEmpty);
  });

  test('sending while not connected is silently dropped', () {
    client.sendCommand('NEXT');
    client.sendTouchOrLaser('TOUCH', 1, 2);
    client.sendTouchOrLaser('LASER', double.nan, double.infinity);
    expect(states, isEmpty);
  });

  test('disconnect forgets the PC and is safe to repeat', () async {
    final port = await closedPort();
    await client.connect('127.0.0.1', port, pin: '123456');
    await client.disconnect();
    await client.disconnect();
    expect(client.host, isNull);
    expect(client.port, isNull);
    expect(client.connectionState, AppConnectionState.disconnected);
  });

  test('manualReconnect does nothing without a previous PC', () async {
    client.manualReconnect();
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(states, isEmpty);
  });

  test('manualReconnect retries the last PC', () async {
    final port = await closedPort();
    await client.connect('127.0.0.1', port, pin: '123456');
    states.clear();
    client.manualReconnect();
    for (var i = 0; i < 100 && states.length < 2; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
    expect(states, [
      AppConnectionState.connecting,
      AppConnectionState.disconnected,
    ]);
  });

  test('an IPv6 host is bracketed for the URI (no FormatException)', () async {
    final s = await ServerSocket.bind(InternetAddress.loopbackIPv6, 0)
        .catchError((_) => ServerSocket.bind(InternetAddress.loopbackIPv4, 0));
    final port = s.port;
    await s.close();
    final r = await client.connect('::1', port, pin: '123456');
    expect(r.error, isNot(ConnectionError.unknown), reason: r.detail);
  });
}
