import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'l10n/app_language.dart';
import 'screens/home/home_screen.dart';
import 'services/background_session.dart';
import 'services/websocket_service.dart';
import 'providers/settings_provider.dart';
import 'services/discovery_service.dart';
import 'theme/app_palette.dart';
import 'theme/app_theme.dart';
import 'widgets/brand/brand_splash.dart';

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
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) => MaterialApp(
          title: 'QuickRemote',
          locale: settings.language.locale,
          supportedLocales: supportedAppLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          debugShowCheckedModeBanner: false,
          // Light and dark follow the system setting.
          themeMode: ThemeMode.system,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          builder: (context, child) {
            BackgroundSession.notificationText = context.l10n.backgroundNotification;
            return AnnotatedRegion<SystemUiOverlayStyle>(
              value: AppTheme.overlayStyle(context.palette),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  child!,
                  BrandSplash(tagline: context.l10n.homeTagline),
                ],
              ),
            );
          },
          home: const HomeScreen(),
        ),
      ),
    );
  }
}

/// Inter and Space Grotesk are bundled under the SIL Open Font License,
/// which travels with them.
void _registerFontLicense() {
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks(['Inter'], await rootBundle.loadString('assets/fonts/OFL.txt'));
    yield LicenseEntryWithLineBreaks(
      ['Space Grotesk'],
      await rootBundle.loadString('assets/fonts/OFL-SpaceGrotesk.txt'),
    );
  });
}
