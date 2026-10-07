import 'dart:io';

import 'package:flutter/foundation.dart';

/// Which remote addresses may talk to the server: only the local network.
///
/// The server listens on every interface. A PC with a public IPv6 address
/// (or no firewall) would otherwise also take PIN attempts from the
/// internet, and pausing all pairing after many wrong PINs would let anyone
/// there keep it paused.
class LocalNetwork {
  /// The PC's own addresses, for the same-subnet check. Refreshed by
  /// [refresh]; until then only private and link-local addresses pass.
  List<InternetAddress> _own = const [];

  Future<void> refresh() async {
    try {
      final interfaces = await NetworkInterface.list(
        includeLoopback: true,
        includeLinkLocal: true,
      );
      _own = [for (final i in interfaces) ...i.addresses];
    } catch (e) {
      debugPrint('LocalNetwork: interface list failed: $e');
    }
  }

  bool allows(InternetAddress remote) => isLocal(remote, _own);

  /// Whether [remote] is on the local network: a private, link-local,
  /// loopback or shared (CGNAT, e.g. Tailscale) address, or one in the same
  /// /24 (IPv4) or /64 (IPv6) as one of the PC's [own] addresses, which
  /// covers networks that hand out public addresses (some campuses, IPv6).
  @visibleForTesting
  static bool isLocal(InternetAddress remote, List<InternetAddress> own) {
    final raw = _unmapped(remote.rawAddress);
    if (raw.length == 4) {
      if (_isPrivateV4(raw)) return true;
      return own.any((a) {
        final o = _unmapped(a.rawAddress);
        return o.length == 4 && _samePrefix(raw, o, 3);
      });
    }
    if (raw.length != 16) return false;
    if (_isPrivateV6(raw)) return true;
    return own.any((a) {
      final o = a.rawAddress;
      return o.length == 16 && _samePrefix(raw, o, 8);
    });
  }

  /// IPv4-mapped IPv6 (`::ffff:a.b.c.d`, how the dual-stack socket reports
  /// IPv4 clients) as its 4 IPv4 bytes.
  static List<int> _unmapped(List<int> raw) {
    if (raw.length == 16 &&
        raw.take(10).every((b) => b == 0) &&
        raw[10] == 0xff &&
        raw[11] == 0xff) {
      return raw.sublist(12);
    }
    return raw;
  }

  static bool _isPrivateV4(List<int> b) =>
      b[0] == 10 || // 10.0.0.0/8
      b[0] == 127 || // loopback
      (b[0] == 172 && b[1] >= 16 && b[1] <= 31) || // 172.16.0.0/12
      (b[0] == 192 && b[1] == 168) || // 192.168.0.0/16
      (b[0] == 169 && b[1] == 254) || // link-local
      (b[0] == 100 && b[1] >= 64 && b[1] <= 127); // 100.64.0.0/10 (CGNAT)

  static bool _isPrivateV6(List<int> b) {
    final loopback = b.take(15).every((x) => x == 0) && b[15] == 1;
    final uniqueLocal = (b[0] & 0xfe) == 0xfc; // fc00::/7
    final linkLocal = b[0] == 0xfe && (b[1] & 0xc0) == 0x80; // fe80::/10
    return loopback || uniqueLocal || linkLocal;
  }

  static bool _samePrefix(List<int> a, List<int> b, int bytes) {
    for (var i = 0; i < bytes; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
