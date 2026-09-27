import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:math';

class NetworkManager {
  static String? _cachedIP;

  static Future<String> getLocalIP({bool force = false}) async {
    if (!force && _cachedIP != null) {
      return _cachedIP!;
    }

    try {
      final result = await Process.run('powershell', [
        '-NoProfile',
        '-NonInteractive',
        '-Command',
        r'(Get-NetIPConfiguration | Where-Object {$_.IPv4DefaultGateway -ne $null} | Select-Object -First 1).IPv4Address.IPAddress'
      ]);
      final output = (result.stdout as String).trim();
      if (output.isNotEmpty && output.contains('.')) {
        _cachedIP = output;
        return output;
      }
    } catch (e) {
      debugPrint('Failed to get IP via PowerShell: $e');
    }

    final interfaces = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
      includeLinkLocal: false,
    );

    const virtualKeywords = [
      'vmware', 'virtualbox', 'vbox', 'hyper-v',
      'docker', 'wsl', 'vmnet', 'vethernet',
    ];

    String? fallbackIP;

    for (final interface in interfaces) {
      final nameLower = interface.name.toLowerCase();
      final isVirtual = virtualKeywords.any((kw) => nameLower.contains(kw));
      if (isVirtual) continue;

      for (final addr in interface.addresses) {
        if (!addr.isLoopback) {
          fallbackIP ??= addr.address;
          _cachedIP = fallbackIP;
          return fallbackIP;
        }
      }
    }
    
    _cachedIP = fallbackIP ?? '127.0.0.1';
    return _cachedIP!;
  }

  static void clearCachedIP() {
    _cachedIP = null;
  }

  static String generateSecurePassword() {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rng = Random.secure();
    return List.generate(32, (index) => chars[rng.nextInt(chars.length)]).join();
  }

  static Future<SecurityContext> loadOrGenerateCert() async {
    final dir = await getApplicationSupportDirectory();
    final certPath = '${dir.path}\\server_cert.pfx';
    final pwdPath = '${dir.path}\\cert_pwd.txt';
    final file = File(certPath);
    final pwdFile = File(pwdPath);

    bool generate = true;
    if (file.existsSync()) {
      final stat = file.statSync();
      if (DateTime.now().difference(stat.modified).inDays < 365) {
        generate = false;
      }
    }

    String certPassword = '1234';
    
    if (generate) {
      debugPrint('Generating new self-signed TLS certificate...');
      certPassword = generateSecurePassword();
      if (file.existsSync()) file.deleteSync();
      pwdFile.writeAsStringSync(certPassword);

      final script = '''
\$cert = New-SelfSignedCertificate -DnsName "QuickRemote" -CertStoreLocation "cert:\\CurrentUser\\My" -ErrorAction Stop
\$pwd = ConvertTo-SecureString -String "$certPassword" -Force -AsPlainText -ErrorAction Stop
Export-PfxCertificate -Cert \$cert -FilePath "$certPath" -Password \$pwd -ErrorAction Stop
Remove-Item -Path "cert:\\CurrentUser\\My\\\$(\$cert.Thumbprint)" -ErrorAction Stop
''';

      final res = await Process.run('powershell', ['-NoProfile', '-NonInteractive', '-Command', script]);
      if (res.exitCode != 0 || !file.existsSync()) {
        throw Exception('Failed to generate TLS certificate via PowerShell: \${res.stderr}');
      }
    } else {
       if (pwdFile.existsSync()) {
         certPassword = pwdFile.readAsStringSync().trim();
       }
    }

    final ctx = SecurityContext();
    ctx.useCertificateChain(certPath, password: certPassword);
    ctx.usePrivateKey(certPath, password: certPassword);
    return ctx;
  }

  static Future<bool> checkNetworkProfile() async {
    try {
      final result = await Process.run('powershell', [
        '-NoProfile',
        '-NonInteractive',
        '-Command',
        r'(Get-NetConnectionProfile | Where-Object {$_.IPv4Connectivity -ne "Disconnected"} | Select-Object -First 1).NetworkCategory',
      ]);
      final output = (result.stdout as String).trim();
      debugPrint('Network profile: \$output');
      return output.toLowerCase() == 'public';
    } catch (e) {
      debugPrint('Failed to check network profile: \$e');
      return false;
    }
  }

  static Future<String?> getActiveInterfaceAlias() async {
    try {
      final result = await Process.run('powershell', [
        '-NoProfile',
        '-NonInteractive',
        '-Command',
        r'(Get-NetConnectionProfile | Where-Object {$_.IPv4Connectivity -ne "Disconnected"} | Select-Object -First 1).InterfaceAlias',
      ]);
      final output = (result.stdout as String).trim();
      return output.isNotEmpty ? output : null;
    } catch (e) {
      debugPrint('Failed to get interface alias: \$e');
      return null;
    }
  }

  static Future<bool> setNetworkProfilePrivate() async {
    try {
      final alias = await getActiveInterfaceAlias();
      if (alias == null) return false;

      final result = await Process.run('powershell', [
        '-NoProfile',
        '-NonInteractive',
        '-Command',
        'Set-NetConnectionProfile -InterfaceAlias "$alias" -NetworkCategory Private',
      ]);

      if (result.exitCode == 0) {
        debugPrint('Network profile set to Private for $alias');
        return true;
      } else {
        debugPrint('Failed to set network profile: ${result.stderr}');
        return false;
      }
    } catch (e) {
      debugPrint('Error setting network profile: \$e');
      return false;
    }
  }

  static Future<void> openNetworkSettings() async {
    try {
      await Process.run('explorer', ['ms-settings:network-wifi']);
    } catch (e) {
      debugPrint('Failed to open network settings: \$e');
    }
  }
}
