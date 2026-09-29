import 'dart:io';
import 'network/linux_network.dart';
import 'network/platform_network.dart';
import 'network/windows_network.dart';

export 'network/platform_network.dart' show FirewallStatus;

/// Static facade over the platform [PlatformNetwork] implementation.
class NetworkManager {
  static final PlatformNetwork _impl = Platform.isLinux ? LinuxNetwork() : WindowsNetwork();
  static String? _cachedIP;

  static Future<String> getLocalIP({bool force = false}) async {
    if (!force && _cachedIP != null) return _cachedIP!;
    return _cachedIP = await _impl.getLocalIP();
  }

  static void clearCachedIP() => _cachedIP = null;

  static Future<SecurityContext> loadOrGenerateCert() => _impl.loadOrGenerateCert();
  static Future<bool> checkNetworkProfile() => _impl.checkNetworkProfile();
  static Future<void> openNetworkSettings() => _impl.openNetworkSettings();
  static Future<FirewallStatus> checkFirewall(int port) => _impl.checkFirewall(port);
  static Future<bool> openFirewallPorts() => _impl.openFirewallPorts();
}
