import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:quick_remote_app/screens/home_screen.dart';
import 'package:quick_remote_app/services/websocket_service.dart';
import 'package:quick_remote_app/services/discovery_service.dart';

class FakeWebSocketService extends WebSocketService {
  @override
  Future<ConnectionResult> connect(String host, int port, {String? pin}) async {
    // Simulate cert mismatch
    return ConnectionResult(
      success: false,
      error: ConnectionError.certMismatch,
      message: 'Sertifika değişti!',
      newFingerprint: 'mock_fingerprint_123',
      mismatchHost: host,
    );
  }

  @override
  Future<ConnectionResult> acceptCertificateAndReconnect(
    String host,
    String newFingerprint, {
    required int port,
    String? pin,
  }) async {
    // Simulate successful reconnect after accepting
    return const ConnectionResult.ok();
  }
}

class FakeDiscoveryService extends DiscoveryService {
  @override
  Future<void> startScanning() async {}
  @override
  Future<void> stopScanning() async {}
}

void main() {
  testWidgets('Sertifika uyuşmazlığı durumunda dialog görünür ve işlem yapılabilir', (WidgetTester tester) async {
    final fakeWs = FakeWebSocketService();
    final fakeDiscovery = FakeDiscoveryService();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<WebSocketService>.value(value: fakeWs),
          ChangeNotifierProvider<DiscoveryService>.value(value: fakeDiscovery),
        ],
        child: const MaterialApp(
          home: HomeScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Trigger manual connect (which will call connect on our fake ws)
    final manualConnectButton = find.text('Manuel bağlantı');
    expect(manualConnectButton, findsOneWidget);
    await tester.tap(manualConnectButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    final connectButton = find.widgetWithText(FilledButton, 'Bağlan');
    expect(connectButton, findsOneWidget);
    
    // Fill IP so it passes validation
    await tester.enterText(find.widgetWithText(TextField, '192.168.1.x'), '127.0.0.1');
    await tester.tap(connectButton);
    
    // We use pump instead of pumpAndSettle because a CircularProgressIndicator might be spinning
    await tester.pump(); // Start connection
    await tester.pump(const Duration(milliseconds: 500)); // Dialog animation

    // Verify dialog appears
    expect(find.text('Güvenlik Uyarısı'), findsOneWidget);
    expect(find.text('Yine de Bağlan ve Güncelle'), findsOneWidget);
    expect(find.text('İptal Et'), findsOneWidget);

    // Tap Cancel
    await tester.tap(find.text('İptal Et'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500)); // Dialog exit animation

    // Dialog should be closed
    expect(find.text('Güvenlik Uyarısı'), findsNothing);
  });
}
