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


Widget _app(WebSocketServerProvider provider, Locale locale, double scale) => MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => AppearanceProvider()),
        ChangeNotifierProvider<WebSocketServerProvider>.value(value: provider),
      ],
      child: MaterialApp(
        locale: locale,
        supportedLocales: supportedAppLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: AppTheme.light,
        builder: (c, child) => MediaQuery(
          data: MediaQuery.of(c).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: const HomeScreen(),
      ),
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({'hide_public_network_warning': true}));

  final providers = <String, WebSocketServerProvider Function()>{
    'stopped': () => _FakeProvider(running: false),
    'starting': () => _FakeProvider(running: false, starting: true),
    'running, no phone': () => _FakeProvider(),
    'two phones, paused': () => _FakeProvider(devices: 2, paired: true, paused: true),
    'public network': () => _FakeProvider(trust: NetworkTrust.untrusted, devices: 1),
  };
  final sizes = <String, (Size, double)>{
    'opening size, text 1.5': (const Size(440, 760), 1.5),
    'opening size, text 2.0': (const Size(440, 760), 2.0),
    'small window': (const Size(380, 420), 1.0),
    'wide': (const Size(1000, 640), 1.0),
    'wide, text 2.0': (const Size(1000, 640), 2.0),
  };
  for (final lang in ['tr', 'en']) {
    for (final p in providers.entries) {
      for (final s in sizes.entries) {
        testWidgets('${p.key} ($lang) at ${s.key}: no overflow, labeled', (tester) async {
          tester.view.physicalSize = s.value.$1;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          final handle = tester.ensureSemantics();
          await tester.pumpWidget(_app(p.value(), Locale(lang), s.value.$2));
          await tester.pump(const Duration(seconds: 1));
          expect(tester.takeException(), isNull);
          await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
          handle.dispose();
          await tester.pumpWidget(const SizedBox());
        });
      }
    }
  }
}
