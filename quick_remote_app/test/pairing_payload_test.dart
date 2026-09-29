import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quick_remote_shared/quick_remote_shared.dart';

void main() {
  final digest = sha256.convert(utf8.encode('certificate'));
  final encoded = PairingPayload.encodeFingerprint(digest.bytes);

  group('PairingPayload.parse', () {
    test('reads the QR code of an older PC (no fingerprint)', () {
      final (payload, error) = PairingPayload.parse('quickremote://192.168.1.20:8090:1234');
      expect(error, isNull);
      expect(payload!.host, '192.168.1.20');
      expect(payload.port, 8090);
      expect(payload.pin, '1234');
      expect(payload.certFingerprint, isNull);
    });

    test('reads the certificate fingerprint', () {
      final (payload, _) = PairingPayload.parse('quickremote://10.0.0.2:8091:482913:$encoded');
      expect(payload!.pin, '482913');
      expect(payload.certFingerprint, encoded);
    });

    test('round-trips through encode', () {
      const original = PairingPayload(host: '10.0.0.2', port: 8095, pin: '482913', certFingerprint: null);
      final (payload, _) = PairingPayload.parse(original.encode());
      expect(payload!.encode(), original.encode());
    });

    test('rejects malformed codes', () {
      expect(PairingPayload.parse('https://example.com').$2, PairingError.notQuickRemote);
      expect(PairingPayload.parse('quickremote://10.0.0.2').$2, PairingError.malformed);
      expect(PairingPayload.parse('quickremote://:8090:1234').$2, PairingError.missingHost);
      expect(PairingPayload.parse('quickremote://10.0.0.2:99999:1234').$2, PairingError.invalidPort);
      expect(PairingPayload.parse('quickremote://10.0.0.2:8090:1234:not-a-hash').$2,
          PairingError.invalidFingerprint);
    });
  });

  group('fingerprint encoding', () {
    test('is 43 base64url characters', () {
      expect(encoded, matches(RegExp(r'^[A-Za-z0-9_-]{43}$')));
    });

    test('converts back to the hex form the phone computes', () {
      expect(PairingPayload.fingerprintToHex(encoded), digest.toString());
    });

    test('rejects values that are not a SHA-256 digest', () {
      expect(PairingPayload.fingerprintToHex(''), isNull);
      expect(PairingPayload.fingerprintToHex(encoded.substring(1)), isNull);
      expect(PairingPayload.fingerprintToHex('${encoded.substring(1)}!'), isNull);
    });
  });
}
