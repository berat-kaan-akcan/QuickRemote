import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quick_remote_pc/services/server/local_network.dart';

void main() {
  bool isLocal(String remote, [List<String> own = const []]) => LocalNetwork.isLocal(
        InternetAddress(remote),
        [for (final a in own) InternetAddress(a)],
      );

  test('accepts private, link-local, loopback and CGNAT addresses', () {
    for (final address in [
      '10.1.2.3', '172.16.0.1', '172.31.255.254', '192.168.1.20', '169.254.3.4',
      '127.0.0.1', '100.64.0.1', '100.127.255.1',
      '::1', 'fe80::1', 'fd12:3456::1', 'fc00::5',
      '::ffff:192.168.1.20',
    ]) {
      expect(isLocal(address), isTrue, reason: address);
    }
  });

  test('refuses public addresses outside the PC\'s networks', () {
    for (final address in [
      '8.8.8.8', '172.32.0.1', '100.128.0.1', '193.140.1.1',
      '2001:db8::1', '2a02:1234::1', '::ffff:8.8.8.8',
    ]) {
      expect(isLocal(address), isFalse, reason: address);
    }
  });

  test('accepts public addresses in the same /24 or /64 as the PC', () {
    expect(isLocal('193.140.1.77', ['193.140.1.10']), isTrue);
    expect(isLocal('::ffff:193.140.1.77', ['193.140.1.10']), isTrue);
    expect(isLocal('193.140.2.77', ['193.140.1.10']), isFalse);
    expect(isLocal('2a02:1234:5678:9abc::77', ['2a02:1234:5678:9abc::10']), isTrue);
    expect(isLocal('2a02:1234:5678:9abd::77', ['2a02:1234:5678:9abc::10']), isFalse);
  });
}
