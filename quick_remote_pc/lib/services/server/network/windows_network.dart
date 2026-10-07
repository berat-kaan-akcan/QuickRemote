import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:nsd/nsd.dart' as nsd;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'dart:math';
import '../../powershell_runner.dart';
import 'platform_network.dart';

class WindowsNetwork implements PlatformNetwork {
  nsd.Registration? _registration;

  @override
  Future<bool> advertise({required String name, required int port}) async {
    await unadvertise();
    try {
      _registration = await nsd.register(nsd.Service(
        name: name,
        type: PlatformNetwork.serviceType,
        port: port,
      ));
      debugPrint('mDNS service registered as $name');
      return true;
    } catch (e) {
      debugPrint('Failed to register mDNS service: $e');
      return false;
    }
  }

  @override
  Future<void> unadvertise() async {
    final registration = _registration;
    _registration = null;
    if (registration == null) return;
    try {
      await nsd.unregister(registration);
    } catch (e) {
      debugPrint('Failed to unregister mDNS service: $e');
    }
  }

  /// The interface addresses [_lastIP] was looked up for.
  String? _lastAddresses;
  String? _lastIP;

  @override
  Future<String> getLocalIP() async {
    // Polled every 5 s. Asking PowerShell for the default route is slow, so
    // only do it when the machine's addresses changed.
    final interfaces = await NetworkInterface.list(type: InternetAddressType.IPv4);
    final addresses = [
      for (final interface in interfaces)
        for (final address in interface.addresses) '${interface.name}=${address.address}',
    ].join(',');
    final cached = _lastIP;
    if (cached != null && addresses == _lastAddresses) return cached;

    final ip = await _defaultRouteIP() ?? await _firstPhysicalIPv4();
    _lastAddresses = addresses;
    _lastIP = ip;
    return ip;
  }

  Future<String?> _defaultRouteIP() async {
    try {
      final output = (await PowerShellRunner.execute(
        r'(Get-NetIPConfiguration | Where-Object {$_.IPv4DefaultGateway -ne $null} | Select-Object -First 1).IPv4Address.IPAddress',
        isPolling: true,
      ))
          .trim();
      if (output.isNotEmpty && output.contains('.')) return output;
    } catch (e) {
      debugPrint('Failed to get IP via PowerShell: $e');
    }
    return null;
  }

  Future<String> _firstPhysicalIPv4() {
    const virtualKeywords = [
      'vmware', 'virtualbox', 'vbox', 'hyper-v',
      'docker', 'wsl', 'vmnet', 'vethernet',
    ];
    return PlatformNetwork.firstPhysicalIPv4((name) => virtualKeywords.any(name.contains));
  }

  static String generateSecurePassword() {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rng = Random.secure();
    return List.generate(32, (index) => chars[rng.nextInt(chars.length)]).join();
  }

  /// Loads the certificate, or makes a new one when there is none or it
  /// cannot be loaded (password file lost or out of step). It is never
  /// renewed otherwise: phones pin its fingerprint and do not look at its
  /// dates, and a new one makes every phone ask the user again.
  @override
  Future<SecurityContext> loadOrGenerateCert() async {
    final dir = await getApplicationSupportDirectory();
    final certPath = p.join(dir.path, 'server_cert.pfx');
    final pwdPath = p.join(dir.path, 'cert_pwd.txt');
    final file = File(certPath);
    final pwdFile = File(pwdPath);

    if (file.existsSync() && pwdFile.existsSync()) {
      try {
        return _context(certPath, pwdFile.readAsStringSync().trim());
      } catch (e) {
        debugPrint('Stored TLS certificate unusable, generating a new one: $e');
      }
    }

    debugPrint('Generating new self-signed TLS certificate...');
    final certPassword = generateSecurePassword();
    if (file.existsSync()) file.deleteSync();
    pwdFile.writeAsStringSync(certPassword);

    // Path and password go in through the environment: a user name with
    // `$` or a backtick would break them inside a PowerShell string.
    const script = r'''
$cert = New-SelfSignedCertificate -DnsName "QuickRemote" -CertStoreLocation "cert:\CurrentUser\My" -NotAfter (Get-Date).AddYears(10) -ErrorAction Stop
$pwd = ConvertTo-SecureString -String $env:QR_CERT_PASSWORD -Force -AsPlainText -ErrorAction Stop
Export-PfxCertificate -Cert $cert -FilePath $env:QR_CERT_PATH -Password $pwd -ErrorAction Stop
Remove-Item -Path "cert:\CurrentUser\My\$($cert.Thumbprint)" -ErrorAction Stop
''';

    final res = await Process.run(
      PowerShellRunner.executable,
      ['-NoProfile', '-NonInteractive', '-Command', script],
      environment: {'QR_CERT_PATH': certPath, 'QR_CERT_PASSWORD': certPassword},
    );
    if (res.exitCode != 0 || !file.existsSync()) {
      throw Exception('Failed to generate TLS certificate via PowerShell: ${res.stderr}');
    }
    return _context(certPath, certPassword);
  }

  static SecurityContext _context(String pfxPath, String password) => SecurityContext()
    ..useCertificateChain(pfxPath, password: password)
    ..usePrivateKey(pfxPath, password: password);

  @override
  Future<NetworkTrust> checkNetworkProfile() async {
    try {
      final output = (await PowerShellRunner.execute(
        r'(Get-NetConnectionProfile | Where-Object {$_.IPv4Connectivity -ne "Disconnected"} | Select-Object -First 1).NetworkCategory',
        isPolling: true,
      ))
          .trim();
      debugPrint('Network profile: $output');
      return switch (output.toLowerCase()) {
        'public' => NetworkTrust.untrusted,
        'private' || 'domainauthenticated' => NetworkTrust.trusted,
        _ => NetworkTrust.unknown,
      };
    } catch (e) {
      debugPrint('Failed to check network profile: $e');
      return NetworkTrust.unknown;
    }
  }

  @override
  Future<void> openNetworkSettings() async {
    try {
      await Process.run('explorer', ['ms-settings:network-wifi']);
    } catch (e) {
      debugPrint('Failed to open network settings: $e');
    }
  }

  // Windows Firewall prompts the user itself when the server first listens.
  @override
  Future<FirewallStatus> checkFirewall(int port) async => FirewallStatus.open;

  @override
  Future<bool> openFirewallPorts() async => true;
}
