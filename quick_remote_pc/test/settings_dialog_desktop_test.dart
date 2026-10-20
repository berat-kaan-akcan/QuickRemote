import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:quick_remote_pc/l10n/app_language.dart';
import 'package:quick_remote_pc/providers/appearance_provider.dart';
import 'package:quick_remote_pc/providers/desktop_provider.dart';
import 'package:quick_remote_pc/providers/language_provider.dart';
import 'package:quick_remote_pc/providers/laser_overlay_provider.dart';
import 'package:quick_remote_pc/providers/server_provider.dart';
import 'package:quick_remote_pc/screens/home/widgets/settings_dialog.dart';
import 'package:quick_remote_pc/services/desktop/autostart.dart';
import 'package:quick_remote_pc/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeAutostart implements Autostart {
  bool enabled = false;
  @override
  Future<bool> isEnabled() async => enabled;
  @override
  Future<bool> setEnabled(bool value) async {
    enabled = value;
    return true;
  }

  @override
  Future<void> refresh() async {}
}

Widget _app(DesktopProvider desktop) => MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => AppearanceProvider()),
        ChangeNotifierProvider(create: (_) => LaserOverlayProvider()),
        ChangeNotifierProvider.value(value: desktop),
      ],
      child: MaterialApp(
        locale: const Locale('en'),
        theme: AppTheme.light,
        supportedLocales: supportedAppLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const Scaffold(body: SettingsDialog()),
      ),
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('the startup switches change the settings', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final autostart = _FakeAutostart();
    final desktop = DesktopProvider(
      server: WebSocketServerProvider(),
      navigatorKey: GlobalKey<NavigatorState>(),
      autostart: autostart,
    );
    await tester.pumpWidget(_app(desktop));
    await tester.pumpAndSettle();

    // No tray in a test: closing would quit, and the switch says why.
    expect(find.text('Startup and tray'), findsOneWidget);
    expect(find.textContaining('has no system tray'), findsOneWidget);

    await tester.tap(find.text('Start at login'));
    await tester.pumpAndSettle();
    expect(autostart.enabled, isTrue);
    expect(desktop.launchAtLogin, isTrue);

    await tester.tap(find.text('Start the server on launch'));
    await tester.pumpAndSettle();
    expect(desktop.startServerOnLaunch, isTrue);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('start_server_on_launch'), isTrue);

    await tester.tap(find.text('Check for updates'));
    await tester.pumpAndSettle();
    expect(desktop.checkUpdates, isFalse);
  });
}
