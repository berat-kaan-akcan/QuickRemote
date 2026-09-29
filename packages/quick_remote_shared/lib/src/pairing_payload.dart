import 'dart:convert';

/// Why a scanned QR code could not be used for pairing.
enum PairingError { notQuickRemote, malformed, missingHost, invalidPort, invalidFingerprint }

/// Contents of the pairing QR code shown by the PC:
/// `quickremote://HOST:PORT:PIN[:FINGERPRINT]`.
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

  String encode() =>
      '$scheme$host:$port:$pin${certFingerprint == null ? '' : ':$certFingerprint'}';

  /// Parses a scanned QR value. Exactly one of the returned fields is non-null.
  static (PairingPayload?, PairingError?) parse(String raw) {
    if (!raw.startsWith(scheme)) return (null, PairingError.notQuickRemote);
    final parts = raw.substring(scheme.length).split(':');
    if (parts.length < 2) return (null, PairingError.malformed);

    final host = parts[0].trim();
    if (host.isEmpty) return (null, PairingError.missingHost);

    final port = int.tryParse(parts[1]);
    if (port == null || port < 1 || port > 65535) return (null, PairingError.invalidPort);

    String? fingerprint;
    if (parts.length >= 4 && parts[3].isNotEmpty) {
      fingerprint = parts[3];
      if (fingerprintToHex(fingerprint) == null) return (null, PairingError.invalidFingerprint);
    }

    return (
      PairingPayload(
        host: host,
        port: port,
        pin: parts.length >= 3 ? parts[2] : '',
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
