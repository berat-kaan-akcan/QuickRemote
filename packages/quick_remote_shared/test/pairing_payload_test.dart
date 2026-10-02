import 'package:quick_remote_shared/quick_remote_shared.dart';
import 'package:test/test.dart';

void main() {
  final digest = List.generate(32, (i) => i * 7 % 256);
  final digestHex = digest.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  final encoded = PairingPayload.encodeFingerprint(digest);

  group('PairingPayload.parse', () {
    test('reads the QR code of an older PC (no fingerprint, 4-digit PIN)', () {
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

    test('accepts a code without a PIN', () {
      final (payload, error) = PairingPayload.parse('quickremote://10.0.0.2:8091');
      expect(error, isNull);
      expect(payload!.pin, '');
    });

    test('reads a bracketed IPv6 host', () {
      final (payload, error) = PairingPayload.parse('quickremote://[fe80::1:2]:8090:482913:$encoded');
      expect(error, isNull);
      expect(payload!.host, 'fe80::1:2');
      expect(payload.port, 8090);
      expect(payload.pin, '482913');
      expect(payload.certFingerprint, encoded);
    });

    test('round-trips through encode', () {
      for (final original in [
        const PairingPayload(host: '10.0.0.2', port: 8095, pin: '482913'),
        PairingPayload(host: '2001:db8::5', port: 8090, pin: '482913', certFingerprint: encoded),
      ]) {
        final (payload, error) = PairingPayload.parse(original.encode());
        expect(error, isNull, reason: original.encode());
        expect(payload!.encode(), original.encode());
        expect(payload.host, original.host);
      }
    });

    test('rejects malformed codes', () {
      expect(PairingPayload.parse('https://example.com').$2, PairingError.notQuickRemote);
      expect(PairingPayload.parse('quickremote://10.0.0.2').$2, PairingError.malformed);
      expect(PairingPayload.parse('quickremote://[fe80::1:8090:1234').$2, PairingError.malformed);
      expect(PairingPayload.parse('quickremote://:8090:1234').$2, PairingError.missingHost);
      expect(PairingPayload.parse('quickremote://10.0.0.2:99999:1234').$2, PairingError.invalidPort);
      expect(PairingPayload.parse('quickremote://10.0.0.2:8090:12a4').$2, PairingError.invalidPin);
      expect(PairingPayload.parse('quickremote://10.0.0.2:8090:12345').$2, PairingError.invalidPin);
      expect(PairingPayload.parse('quickremote://10.0.0.2:8090:1234:not-a-hash').$2,
          PairingError.invalidFingerprint);
    });
  });

  group('fingerprint encoding', () {
    test('is 43 base64url characters', () {
      expect(encoded, matches(RegExp(r'^[A-Za-z0-9_-]{43}$')));
    });

    test('converts back to the hex form the phone computes', () {
      expect(PairingPayload.fingerprintToHex(encoded), digestHex);
    });

    test('rejects values that are not a SHA-256 digest', () {
      expect(PairingPayload.fingerprintToHex(''), isNull);
      expect(PairingPayload.fingerprintToHex(encoded.substring(1)), isNull);
      expect(PairingPayload.fingerprintToHex('${encoded.substring(1)}!'), isNull);
    });
  });
}
