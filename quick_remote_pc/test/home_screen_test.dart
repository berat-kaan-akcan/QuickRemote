import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:quick_remote_pc/l10n/app_language.dart';
import 'package:quick_remote_pc/providers/appearance_provider.dart';
import 'package:quick_remote_pc/providers/language_provider.dart';
import 'package:quick_remote_pc/providers/server_provider.dart';
import 'package:quick_remote_pc/screens/home/home_screen.dart';
import 'package:quick_remote_pc/services/server/network_manager.dart';
import 'package:quick_remote_pc/services/websocket_server.dart';
import 'package:quick_remote_pc/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeProvider extends WebSocketServerProvider {
  _FakeProvider({
    this.running = true,
    this.starting = false,
    this.trust = NetworkTrust.trusted,
    this.devices = 0,
    this.paired = false,
    this.paused = false,
  });
  final bool running, starting, paired, paused;
  final NetworkTrust trust;
  final int devices;
  @override
  bool get isRunning => running;
  @override
  bool get isStarting => starting;
  @override
  String get localIP => '192.168.1.42';
  @override
  String get pin => '482917';
  @override
  NetworkTrust get networkTrust => trust;
  @override
  String? get certFingerprint => 'Tyq5n1-6GKqC0XYXr2bTqH3RQZbZ2nS9n6mXc0Jm4hU';
  @override
  bool get pairingPaused => paused;
  @override
  bool get pairedOnce => paired;
  @override
  int get clientCount => devices;
  @override
  List<ConnectedClient> get connectedClients => [
        if (devices > 0) ConnectedClient(1, '192.168.1.37', DateTime(2026, 10, 18, 10, 24), name: 'Galaxy S23 FE'),
        if (devices > 1) ConnectedClient(2, '192.168.1.51', DateTime(2026, 10, 18, 10, 31), name: 'Pixel 8'),
      ];
}


Widget _app(WebSocketServerProvider provider) => MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => AppearanceProvider()),
        ChangeNotifierProvider<WebSocketServerProvider>.value(value: provider),
      ],
      child: MaterialApp(
        locale: const Locale('tr'),
        supportedLocales: supportedAppLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: AppTheme.light,
        home: const HomeScreen(),
      ),
    );

Future<void> _pump(WidgetTester tester, WebSocketServerProvider provider, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(_app(provider));
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({'hide_public_network_warning': true}));

  testWidgets('stopped: the status card and a Start key at the bottom', (tester) async {
    await _pump(tester, _FakeProvider(running: false), const Size(440, 760));
    expect(find.text('Sunucu Kapalı'), findsOneWidget);
    expect(find.text('Sunucuyu Başlat'), findsOneWidget);
    expect(find.text('Sunucuyu Durdur'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('starting: Stop at the bottom while the network is read', (tester) async {
    await _pump(tester, _FakeProvider(running: false, starting: true), const Size(440, 760));
    expect(find.text('Sunucu açılıyor'), findsOneWidget);
    expect(find.text('Sunucuyu Durdur'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a public network turns the card amber with a Settings key', (tester) async {
    await _pump(tester, _FakeProvider(trust: NetworkTrust.untrusted), const Size(440, 760));
    expect(find.text('Ayarlar'), findsOneWidget);
    expect(find.text('Telefon bekleniyor'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('paired: the code stays hidden until shown, then can be hidden', (tester) async {
    await _pump(tester, _FakeProvider(devices: 1, paired: true), const Size(440, 760));
    expect(find.text('Sunucu Açık'), findsOneWidget);
    expect(find.textContaining('1 telefon bağlı'), findsOneWidget);
    expect(find.text('Galaxy S23 FE'), findsOneWidget);
    expect(find.text('Sunucuyu Durdur'), findsOneWidget);
    expect(find.text('Kodu gizle'), findsNothing);

    await tester.tap(find.text('Kodu göster'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Kodu göster'), findsNothing);
    await tester.tap(find.text('Kodu gizle'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Kodu göster'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a short window scrolls and keeps Stop on screen', (tester) async {
    await _pump(tester, _FakeProvider(devices: 2, paired: true, paused: true), const Size(440, 560));
    expect(tester.takeException(), isNull);
    final stop = tester.getRect(find.text('Sunucuyu Durdur'));
    expect(stop.bottom, lessThanOrEqualTo(560));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a wide window puts the code beside the side pane', (tester) async {
    await _pump(tester, _FakeProvider(devices: 1), const Size(1000, 640));
    final code = tester.getRect(find.text('Bağlanmak için QR kodu tarayın'));
    final status = tester.getRect(find.text('Sunucu Açık'));
    expect(code.left, greaterThan(status.right));
    expect(find.text('Sunucuyu Durdur'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
