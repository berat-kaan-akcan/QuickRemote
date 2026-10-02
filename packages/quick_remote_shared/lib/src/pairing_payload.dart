import 'dart:convert';

/// Why a scanned QR code could not be used for pairing.
enum PairingError { notQuickRemote, malformed, missingHost, invalidPort, invalidPin, invalidFingerprint }

/// Contents of the pairing QR code shown by the PC:
/// `quickremote://HOST:PORT:PIN[:FINGERPRINT]`, with an IPv6 HOST in brackets.
///
/// FINGERPRINT is the SHA-256 of the server's TLS certificate (DER) in
/// base64url without padding. The phone pins it before the first handshake,
/// so the first connection cannot be intercepted. Older phones ignore the
/// fourth field, and older PCs don't send it.
class PairingPayload {
  const PairingPayload({
    required this.host,
    required this.port,
    required this.pin,
    this.certFingerprint,
  });

  static const scheme = 'quickremote://';

  final String host;
  final int port;
  final String pin;
  final String? certFingerprint;

  String encode() {
    final h = host.contains(':') ? '[$host]' : host;
    return '$scheme$h:$port:$pin${certFingerprint == null ? '' : ':$certFingerprint'}';
  }

  /// 6 digits; 4 from PCs older than the 6-digit PIN. Empty when the QR code
  /// carries none (the user types it).
  static final _pinPattern = RegExp(r'^(\d{4}|\d{6})?$');

  /// Parses a scanned QR value. Exactly one of the returned fields is non-null.
  static (PairingPayload?, PairingError?) parse(String raw) {
    if (!raw.startsWith(scheme)) return (null, PairingError.notQuickRemote);
    var rest = raw.substring(scheme.length);
    String host;
    if (rest.startsWith('[')) {
      final close = rest.indexOf(']');
      if (close < 0) return (null, PairingError.malformed);
      host = rest.substring(1, close).trim();
      rest = rest.substring(close + 1);
      if (!rest.startsWith(':')) return (null, PairingError.malformed);
      rest = rest.substring(1);
    } else {
      final colon = rest.indexOf(':');
      if (colon < 0) return (null, PairingError.malformed);
      host = rest.substring(0, colon).trim();
      rest = rest.substring(colon + 1);
    }
    if (host.isEmpty) return (null, PairingError.missingHost);
    // HOST at index 0, so the indexes below match the format.
    final parts = [host, ...rest.split(':')];

    final port = int.tryParse(parts[1]);
    if (port == null || port < 1 || port > 65535) return (null, PairingError.invalidPort);

    String? fingerprint;
    if (parts.length >= 4 && parts[3].isNotEmpty) {
      fingerprint = parts[3];
      if (fingerprintToHex(fingerprint) == null) return (null, PairingError.invalidFingerprint);
    }

    final pin = parts.length >= 3 ? parts[2] : '';
    if (!_pinPattern.hasMatch(pin)) return (null, PairingError.invalidPin);

    return (
      PairingPayload(
        host: host,
        port: port,
        pin: pin,
        certFingerprint: fingerprint,
      ),
      null,
    );
  }

  /// Encodes a SHA-256 digest for the QR code (base64url, no padding).
  static String encodeFingerprint(List<int> sha256Digest) =>
      base64Url.encode(sha256Digest).replaceAll('=', '');

  /// Converts a QR fingerprint to lower-case hex, the form the phone stores.
  /// Returns null unless it decodes to exactly 32 bytes.
  static String? fingerprintToHex(String encoded) {
    if (!RegExp(r'^[A-Za-z0-9_-]{43}$').hasMatch(encoded)) return null;
    final List<int> bytes;
    try {
      bytes = base64Url.decode('$encoded=');
    } on FormatException {
      return null;
    }
    if (bytes.length != 32) return null;
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}
