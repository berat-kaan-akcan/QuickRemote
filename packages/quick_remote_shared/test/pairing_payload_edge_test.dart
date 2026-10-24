import 'package:quick_remote_shared/quick_remote_shared.dart';
import 'package:test/test.dart';

void main() {
  final digest = List.generate(32, (i) => (i * 11 + 3) % 256);
  final fp = PairingPayload.encodeFingerprint(digest);

  PairingError? errorOf(String raw) => PairingPayload.parse(raw).$2;

  test('exactly one of payload and error is set', () {
    for (final raw in [
      '',
      'quickremote://',
      'quickremote://h:1',
      'quickremote://h:0',
      'QUICKREMOTE://h:1',
      'quickremote://[::1]:80:123456:$fp',
    ]) {
      final (p, e) = PairingPayload.parse(raw);
      expect((p == null) != (e == null), isTrue, reason: raw);
    }
  });

  test('scheme must match exactly', () {
    expect(errorOf(''), PairingError.notQuickRemote);
    expect(errorOf('QUICKREMOTE://10.0.0.2:8090:123456'),
        PairingError.notQuickRemote);
    expect(errorOf(' quickremote://10.0.0.2:8090:123456'),
        PairingError.notQuickRemote);
    expect(errorOf('quickremote:/10.0.0.2:8090'), PairingError.notQuickRemote);
  });

  test('empty or blank host', () {
    expect(errorOf('quickremote://'), PairingError.malformed);
    expect(errorOf('quickremote://[]:8090:123456'), PairingError.missingHost);
    expect(errorOf('quickremote://  :8090:123456'), PairingError.missingHost);
  });

  test('port bounds', () {
    expect(errorOf('quickremote://h:0:123456'), PairingError.invalidPort);
    expect(errorOf('quickremote://h:65536:123456'), PairingError.invalidPort);
    expect(errorOf('quickremote://h:-1:123456'), PairingError.invalidPort);
    expect(errorOf('quickremote://h::123456'), PairingError.invalidPort);
    expect(errorOf('quickremote://h:80x:123456'), PairingError.invalidPort);
    expect(PairingPayload.parse('quickremote://h:1:123456').$1!.port, 1);
    expect(PairingPayload.parse('quickremote://h:65535:123456').$1!.port,
        65535);
  });

  test('pin must be 4 or 6 digits, or empty', () {
    for (final pin in ['1', '12', '123', '12345', '1234567', 'abcdef', '12 456']) {
      expect(errorOf('quickremote://h:80:$pin'), PairingError.invalidPin,
          reason: pin);
    }
    for (final pin in ['1234', '123456', '000000']) {
      expect(PairingPayload.parse('quickremote://h:80:$pin').$1!.pin, pin);
    }
    // Arabic-Indic digits are not \d in Dart's RegExp (ASCII only).
    expect(errorOf('quickremote://h:80:١٢٣٤'),
        PairingError.invalidPin);
  });

  test('an empty fingerprint field counts as none', () {
    final (p, e) = PairingPayload.parse('quickremote://h:80:123456:');
    expect(e, isNull);
    expect(p!.certFingerprint, isNull);
  });

  test('fingerprint is checked before the pin', () {
    expect(errorOf('quickremote://h:80:bad:xyz'),
        PairingError.invalidFingerprint);
  });

  test('a fingerprint of the wrong length or alphabet is refused', () {
    expect(errorOf('quickremote://h:80:123456:${fp}A'),
        PairingError.invalidFingerprint);
    expect(errorOf('quickremote://h:80:123456:${fp.substring(0, 42)}'),
        PairingError.invalidFingerprint);
    expect(errorOf('quickremote://h:80:123456:${fp.substring(0, 42)}+'),
        PairingError.invalidFingerprint);
    expect(errorOf('quickremote://h:80:123456:${fp.substring(0, 42)}='),
        PairingError.invalidFingerprint);
  });

  test('extra trailing fields are ignored (newer PCs)', () {
    final (p, e) = PairingPayload.parse('quickremote://h:80:123456:$fp:extra:1');
    expect(e, isNull);
    expect(p!.certFingerprint, fp);
  });

  test('bracketed host needs a colon after the bracket', () {
    expect(errorOf('quickremote://[::1]8090:123456'), PairingError.malformed);
    expect(errorOf('quickremote://[::1'), PairingError.malformed);
    final (p, e) = PairingPayload.parse('quickremote://[::1]:8090:123456');
    expect(e, isNull);
    expect(p!.host, '::1');
  });

  test('unbracketed IPv6 cannot be parsed back, bracketed one is encoded', () {
    const v6 = PairingPayload(host: 'fe80::1', port: 80, pin: '123456');
    expect(v6.encode(), 'quickremote://[fe80::1]:80:123456');
    const v4 = PairingPayload(host: '1.2.3.4', port: 80, pin: '123456');
    expect(v4.encode(), 'quickremote://1.2.3.4:80:123456');
  });

  test('fingerprint hex is lower-case, 64 chars, and URL-safe input only', () {
    final hex = PairingPayload.fingerprintToHex(fp)!;
    expect(hex, hasLength(64));
    expect(hex, hex.toLowerCase());
    // Standard base64 characters are not base64url.
    final std = fp.replaceAll('-', '+').replaceAll('_', '/');
    if (std != fp) {
      expect(PairingPayload.fingerprintToHex(std), isNull);
    }
  });

  test('encodeFingerprint strips padding', () {
    expect(PairingPayload.encodeFingerprint([1, 2, 3, 4]), isNot(contains('=')));
  });

  test('verificationCode of a short hex string throws instead of lying', () {
    expect(() => PairingPayload.verificationCode('abcd'), throwsRangeError);
    expect(PairingPayload.verificationCode('0123456789abcdef'),
        '0123-4567-89AB-CDEF');
  });
}
