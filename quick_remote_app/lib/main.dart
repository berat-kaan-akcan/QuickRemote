import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'services/websocket_service.dart';
import 'providers/settings_provider.dart';
import 'services/discovery_service.dart';

// Background execution starts with a remote screen (services/background_session.dart).
void main() {
  _registerFontLicense();
  runApp(const QuickRemoteApp());
}

class QuickRemoteApp extends StatelessWidget {
  const QuickRemoteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        // Hands the phone's PC-side settings to the connection.
        ChangeNotifierProxyProvider<SettingsProvider, WebSocketService>(
          create: (_) => WebSocketService(),
          update: (_, settings, service) =>
              service!..setKeepInkOnSlideChange(settings.keepInkOnSlideChange),
        ),
        ChangeNotifierProvider(create: (_) => DiscoveryService()),
      ],
      child: MaterialApp(
        title: 'QuickRemote',
        debugShowCheckedModeBanner: false,
        themeMode: ThemeMode.dark,
        darkTheme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF0F172A), // Deep Space Black
          colorSchemeSeed: const Color(0xFF005B96),
          useMaterial3: true,
          fontFamily: 'Inter',
        ),
        home: const HomeScreen(),
      ),
    );
  }
}

/// Inter is bundled under the SIL Open Font License, which travels with it.
void _registerFontLicense() {
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks(['Inter'], await rootBundle.loadString('assets/fonts/OFL.txt'));
  });
}
