import 'dart:io';

enum FirewallStatus {
  /// No firewall, or the server ports are allowed.
  open,

  /// A firewall is active and the server ports are not allowed.
  blocked,

  /// A firewall is active but its rules can't be read without root (ufw).
  unknown,
}

/// OS-specific networking: local IP, TLS certificate, network profile and firewall.
abstract class PlatformNetwork {
  Future<String> getLocalIP();
  Future<SecurityContext> loadOrGenerateCert();

  /// True when the active network is untrusted (Windows "Public" profile,
  /// firewalld public/external zone on Linux).
  ///
  /// The app only warns about it. It deliberately never marks the network as
  /// trusted itself: that would relax the firewall for the whole machine.
  Future<bool> checkNetworkProfile();
  Future<void> openNetworkSettings();

  Future<FirewallStatus> checkFirewall(int port);

  /// Allows the server port range (and mDNS) through the firewall. Asks for
  /// the admin password where needed.
  Future<bool> openFirewallPorts();

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
