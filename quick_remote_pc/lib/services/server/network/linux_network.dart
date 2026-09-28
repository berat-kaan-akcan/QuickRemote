import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'platform_network.dart';

class LinuxNetwork implements PlatformNetwork {
  static const _virtualPrefixes = [
    'lo', 'docker', 'veth', 'virbr', 'br-', 'vmnet', 'vboxnet',
    'tailscale', 'zt', 'wg', 'tun', 'tap', 'waydroid',
  ];

  // firewalld zones that treat the network as untrusted.
  static const _untrustedZones = {'public', 'external', 'dmz', 'block', 'drop'};
  static final _zoneName = RegExp(r'^[A-Za-z0-9_-]+$');

  Future<ProcessResult?> _run(String exe, List<String> args) async {
    try {
      return await Process.run(exe, args, environment: const {'LC_ALL': 'C'});
    } catch (_) {
      return null; // executable not installed
    }
  }

  /// Parses `ip route get` output: "1.1.1.1 via 192.168.1.1 dev wlan0 src 192.168.1.177 ..."
  @visibleForTesting
  static ({String? dev, String? src}) parseRoute(String output) => (
        dev: RegExp(r'\bdev\s+(\S+)').firstMatch(output)?.group(1),
        src: RegExp(r'\bsrc\s+(\S+)').firstMatch(output)?.group(1),
      );

  Future<({String? dev, String? src})> _defaultRoute() async {
    final result = await _run('ip', ['-4', 'route', 'get', '1.1.1.1']);
    if (result == null || result.exitCode != 0) return (dev: null, src: null);
    return parseRoute(result.stdout as String);
  }

  @override
  Future<String> getLocalIP() async {
    final route = await _defaultRoute();
    if (route.src != null) return route.src!;
    return PlatformNetwork.firstPhysicalIPv4((name) => _virtualPrefixes.any(name.startsWith));
  }

  @override
  Future<SecurityContext> loadOrGenerateCert() async {
    final dir = await getApplicationSupportDirectory();
    await dir.create(recursive: true);
    final certPath = p.join(dir.path, 'server_cert.pem');
    final keyPath = p.join(dir.path, 'server_key.pem');
    final cert = File(certPath);
    final key = File(keyPath);

    final fresh = cert.existsSync() &&
        key.existsSync() &&
        DateTime.now().difference(cert.statSync().modified).inDays < 365;

    if (!fresh) {
      debugPrint('Generating new self-signed TLS certificate with openssl...');
      final result = await _run('openssl', [
        'req', '-x509', '-newkey', 'rsa:2048', '-nodes',
        '-keyout', keyPath, '-out', certPath,
        '-days', '825', '-subj', '/CN=QuickRemote',
      ]);
      if (result == null) {
        throw Exception('openssl bulunamadı. TLS sertifikası için openssl paketini kurun.');
      }
      if (result.exitCode != 0 || !cert.existsSync()) {
        throw Exception('Failed to generate TLS certificate via openssl: ${result.stderr}');
      }
      await _run('chmod', ['600', keyPath]);
    }

    return SecurityContext()
      ..useCertificateChain(certPath)
      ..usePrivateKey(keyPath);
  }

  // ── firewalld / ufw ──

  Future<bool> _firewalldActive() async {
    final result = await _run('firewall-cmd', ['--state']);
    return result != null && result.exitCode == 0;
  }

  Future<bool> _ufwActive() async {
    final result = await _run('systemctl', ['is-active', '--quiet', 'ufw']);
    return result != null && result.exitCode == 0;
  }

  Future<String?> _activeZone() async {
    final dev = (await _defaultRoute()).dev;
    ProcessResult? result;
    if (dev != null) {
      result = await _run('firewall-cmd', ['--get-zone-of-interface=$dev']);
    }
    if (result == null || result.exitCode != 0) {
      result = await _run('firewall-cmd', ['--get-default-zone']);
    }
    final zone = (result?.stdout as String?)?.trim() ?? '';
    return _zoneName.hasMatch(zone) ? zone : null;
  }

  @override
  Future<bool> checkNetworkProfile() async {
    if (!await _firewalldActive()) return false;
    final zone = await _activeZone();
    return zone != null && _untrustedZones.contains(zone);
  }

  @override
  Future<bool> setNetworkProfilePrivate() async {
    final dev = (await _defaultRoute()).dev;
    if (dev == null) return false;
    final conn = await _run('nmcli', ['-g', 'GENERAL.CONNECTION', 'device', 'show', dev]);
    final name = (conn?.stdout as String?)?.trim() ?? '';
    if (conn == null || conn.exitCode != 0 || name.isEmpty) return false;

    final modify = await _run('nmcli', ['connection', 'modify', name, 'connection.zone', 'home']);
    if (modify == null || modify.exitCode != 0) {
      debugPrint('Failed to set firewalld zone: ${modify?.stderr}');
      return false;
    }
    await _run('nmcli', ['device', 'reapply', dev]);
    return true;
  }

  @override
  Future<void> openNetworkSettings() async {
    final desktop = (Platform.environment['XDG_CURRENT_DESKTOP'] ?? '').toUpperCase();
    final candidates = <(String, List<String>)>[
      if (desktop.contains('KDE')) ('systemsettings', ['kcm_networkmanagement']),
      if (desktop.contains('GNOME')) ('gnome-control-center', ['wifi']),
      ('nm-connection-editor', []),
      ('systemsettings', ['kcm_networkmanagement']),
      ('gnome-control-center', ['wifi']),
    ];
    for (final (exe, args) in candidates) {
      try {
        await Process.start(exe, args, mode: ProcessStartMode.detached);
        return;
      } catch (_) {}
    }
    debugPrint('No network settings application found');
  }

  @override
  Future<FirewallStatus> checkFirewall(int port) async {
    if (await _firewalldActive()) {
      final zone = await _activeZone();
      if (zone == null) return FirewallStatus.unknown;
      final target = await _run('firewall-cmd', ['--permanent', '--zone=$zone', '--get-target']);
      if ((target?.stdout as String?)?.trim() == 'ACCEPT') return FirewallStatus.open;
      final range = await _run('firewall-cmd', [
        '--zone=$zone',
        '--query-port=${PlatformNetwork.serverPortFirst}-${PlatformNetwork.serverPortLast}/tcp',
      ]);
      if (range?.exitCode == 0) return FirewallStatus.open;
      final single = await _run('firewall-cmd', ['--zone=$zone', '--query-port=$port/tcp']);
      return single?.exitCode == 0 ? FirewallStatus.open : FirewallStatus.blocked;
    }
    // ufw rules can only be read as root.
    if (await _ufwActive()) return FirewallStatus.unknown;
    return FirewallStatus.open;
  }

  @override
  Future<bool> openFirewallPorts() async {
    const first = PlatformNetwork.serverPortFirst;
    const last = PlatformNetwork.serverPortLast;
    String? script;
    if (await _firewalldActive()) {
      final zone = await _activeZone();
      if (zone == null) return false;
      script = 'firewall-cmd --permanent --zone=$zone --add-port=$first-$last/tcp && '
          'firewall-cmd --permanent --zone=$zone --add-service=mdns && '
          'firewall-cmd --reload';
    } else if (await _ufwActive()) {
      script = 'ufw allow $first:$last/tcp && ufw allow 5353/udp';
    }
    if (script == null) return true;
    final result = await _run('pkexec', ['sh', '-c', script]);
    return result != null && result.exitCode == 0;
  }
}
