import 'dart:io';

/// Why the TLS certificate could not be set up; the UI words it.
enum TlsSetupError { opensslMissing, keyReadable }

class TlsSetupException implements Exception {
  const TlsSetupException(this.error, [this.detail]);

  final TlsSetupError error;

  /// Untranslated detail (a path).
  final String? detail;

  @override
  String toString() => 'TlsSetupException(${error.name}${detail == null ? '' : ': $detail'})';
}

enum FirewallStatus {
  /// No firewall, or the server ports are allowed.
  open,

  /// A firewall is active and the server ports are not allowed.
  blocked,

  /// A firewall is active but its rules can't be read without root (ufw).
  unknown,
}

/// How far the active network can be trusted, as the OS classifies it.
enum NetworkTrust {
  /// Windows "Private"/"Domain" profile, or a trusted firewalld zone.
  trusted,

  /// Windows "Public" profile, or an untrusted firewalld zone.
  untrusted,

  /// The OS has no classification: no firewalld on Linux, or the query failed.
  unknown,
}

/// OS-specific networking: local IP, TLS certificate, network profile and firewall.
abstract class PlatformNetwork {
  Future<String> getLocalIP();
  Future<SecurityContext> loadOrGenerateCert();

  /// How the OS classifies the active network (Windows network profile,
  /// firewalld zone on Linux).
  ///
  /// The app only warns about untrusted networks. It deliberately never marks
  /// the network as trusted itself: that would relax the firewall for the
  /// whole machine.
  Future<NetworkTrust> checkNetworkProfile();
  Future<void> openNetworkSettings();

  Future<FirewallStatus> checkFirewall(int port);

  /// Allows the server port range (and mDNS) through the firewall. Asks for
  /// the admin password where needed.
  Future<bool> openFirewallPorts();

  /// Advertises the server as `_quickremote._tcp` over mDNS, replacing an
  /// earlier advertisement. Returns false when that failed; the phone then
  /// needs the QR code or the manual address.
  Future<bool> advertise({required String name, required int port});

  /// Withdraws the advertisement, so phones stop listing a stopped server.
  Future<void> unadvertise();

  static const serviceType = '_quickremote._tcp';

  static const serverPortFirst = 8090;
  static const serverPortLast = 8099;

  /// First non-loopback IPv4 of an interface for which [isVirtual] is false.
  static Future<String> firstPhysicalIPv4(bool Function(String lowerName) isVirtual) async {
    final interfaces = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
      includeLinkLocal: false,
    );
    for (final interface in interfaces) {
      if (isVirtual(interface.name.toLowerCase())) continue;
      for (final addr in interface.addresses) {
        if (!addr.isLoopback) return addr.address;
      }
    }
    return '127.0.0.1';
  }
}
