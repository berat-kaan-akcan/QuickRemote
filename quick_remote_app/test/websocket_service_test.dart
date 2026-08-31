import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quick_remote_app/services/websocket_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  HttpServer? server;
  int port = 0;
  String expectedPin = '1234';
  int failedAttempts = 0;

  // Generate a temporary certificate using PowerShell (Windows only test)
  Future<SecurityContext> generateTempCert() async {
    final dir = Directory.systemTemp.createTempSync('qr_test_cert');
    final certPath = '${dir.path}\\test_cert.pfx';

    final script = '''
\$cert = New-SelfSignedCertificate -DnsName "localhost" -CertStoreLocation "cert:\\CurrentUser\\My"
\$pwd = ConvertTo-SecureString -String "1234" -Force -AsPlainText
Export-PfxCertificate -Cert \$cert -FilePath "$certPath" -Password \$pwd
Remove-Item -Path "cert:\\CurrentUser\\My\\\$(\$cert.Thumbprint)"
''';

    await Process.run('powershell', ['-NoProfile', '-NonInteractive', '-Command', script]);
    
    final ctx = SecurityContext();
    ctx.useCertificateChain(certPath, password: '1234');
    ctx.usePrivateKey(certPath, password: '1234');
    
    // Wait, the fingerprint is calculated from the DER certificate, not the PFX.
    // The client will see the DER. We can just capture it on the first connection.
    
    return ctx;
  }

  setUpAll(() async {
    HttpOverrides.global = null;
    SharedPreferences.setMockInitialValues({});
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    failedAttempts = 0;
    
    final ctx = await generateTempCert();
    server = await HttpServer.bindSecure(InternetAddress.loopbackIPv4, 0, ctx);
    port = server!.port;

    server!.listen((HttpRequest request) async {
      if (failedAttempts >= 5) {
        request.response
          ..statusCode = HttpStatus.forbidden
          ..write('Too many failed attempts. Try again later.')
          ..close();
        return;
      }

      if (WebSocketTransformer.isUpgradeRequest(request)) {
        final ws = await WebSocketTransformer.upgrade(request);
        ws.listen((data) {
          final msg = jsonDecode(data as String);
          if (msg['auth'] != null) {
            if (msg['auth'] == expectedPin) {
              failedAttempts = 0;
              ws.add(jsonEncode({'type': 'auth', 'status': 'ok'}));
            } else {
              failedAttempts++;
              ws.add(jsonEncode({'type': 'auth', 'status': 'fail'}));
              ws.close(4003, 'Invalid PIN');
            }
          }
        });
      }
    });
  });

  tearDown(() async {
    await server?.close(force: true);
  });

  group('WebSocketService Integration Tests', () {
    test('a) Doğru PIN ile başarılı bağlantı', () async {
      final wsService = WebSocketService();
      final result = await wsService.connect('127.0.0.1', port, pin: '1234');
      
      expect(result.success, true);
      expect(wsService.isConnected, true);
      expect(wsService.connectionState, AppConnectionState.connected);
      
      await wsService.disconnect();
    });

    test('b) Yanlış PIN ile bağlantının reddedilmesi', () async {
      final wsService = WebSocketService();
      final result = await wsService.connect('127.0.0.1', port, pin: '9999');
      
      expect(result.success, false);
      expect(result.error, ConnectionError.wrongPin);
      expect(wsService.isConnected, false);
    });

    test('c) Art arda 5+ yanlış PIN sonrası IP blok mesajının alınması', () async {
      final wsService = WebSocketService();
      
      // Send 5 wrong PINs
      for (var i = 0; i < 5; i++) {
        await wsService.connect('127.0.0.1', port, pin: '9999');
      }
      
      // 6th attempt should hit the HTTP 403 block before upgrading to WS
      final result = await wsService.connect('127.0.0.1', port, pin: '1234');
      
      expect(result.success, false);
      // Since it rejects at HTTP level, HandshakeException or SocketException will occur
      // WebSocketService maps HandshakeException to unknown if not cert mismatch
      expect(result.error != ConnectionError.none, true);
    });

    test('d) Sertifika uyuşmazlığı durumunda doğru hata dönmesi', () async {
      final wsService = WebSocketService();
      
      // First connection establishes TOFU
      final r1 = await wsService.connect('127.0.0.1', port, pin: '1234');
      expect(r1.success, true);
      await wsService.disconnect();
      
      // Modify SharedPreferences to simulate a cert mismatch
      final prefs = await SharedPreferences.getInstance();
      prefs.setString('cert_fingerprint_127.0.0.1', 'fake_fingerprint_123');
      
      // Second connection should fail with certMismatch
      final r2 = await wsService.connect('127.0.0.1', port, pin: '1234');
      expect(r2.success, false);
      expect(r2.error, ConnectionError.certMismatch);
      expect(r2.newFingerprint, isNotNull);
      expect(r2.mismatchHost, '127.0.0.1');
    });
  });
}
