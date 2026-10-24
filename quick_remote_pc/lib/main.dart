import 'package:flutter/material.dart' hide Size;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'app_version.dart';
import 'l10n/app_language.dart';
import 'screens/home/home_screen.dart';
import 'providers/appearance_provider.dart';
import 'providers/language_provider.dart';
import 'providers/laser_overlay_provider.dart';
import 'providers/server_provider.dart';
import 'providers/desktop_provider.dart';
import 'services/app_log_setup.dart';
import 'services/desktop/desktop_policy.dart';
import 'services/desktop/problem_report.dart';
import 'services/linux/bluez_hid_repair.dart';
import 'services/linux/desktop_entry.dart';
import 'theme/app_theme.dart';
import 'widgets/min_size.dart';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  // debugPrint and uncaught errors go to a local log file (Settings exports it).
  installAppLog(getApplicationSupportDirectory().then((dir) => Directory(p.join(dir.path, 'logs'))));
  debugPrint('QuickRemote PC $appVersion, ${ProblemReport.platform}');
  _registerFontLicense();

  await windowManager.ensureInitialized();

  final windowOptions = WindowOptions(
    size: const ui.Size(440, 760),
    minimumSize: const ui.Size(380, 560),
    center: true,
    title: 'QuickRemote PC',
    titleBarStyle: TitleBarStyle.normal,
  );

  // Started at login: the runner keeps the window hidden, and so does this;
  // DesktopProvider shows it when there is no tray to open it from.
  final minimized = startedMinimized(args);
  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    if (minimized) return;
    await windowManager.show();
    await windowManager.focus();
  });

  final server = WebSocketServerProvider();
  final desktop = DesktopProvider(server: server, navigatorKey: GlobalKey<NavigatorState>());
  runApp(QuickRemotePC(server: server, desktop: desktop));
  // The tray, close-to-tray, the server on launch and the update check.
  desktop.start(minimized: minimized);

  // Gives the window its icon in the taskbar (Wayland finds it by app id).
  if (Platform.isLinux) DesktopEntry.ensureInstalled();
  // Lets the phone's Bluetooth remote fix a computer that refuses it.
  if (Platform.isLinux) BluezHidRepair.instance.start();
}

class QuickRemotePC extends StatelessWidget {
  const QuickRemotePC({super.key, required this.server, required this.desktop});

  final WebSocketServerProvider server;
  final DesktopProvider desktop;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => AppearanceProvider()),
        ChangeNotifierProvider(create: (_) => LaserOverlayProvider(), lazy: false),
        ChangeNotifierProvider.value(value: server),
        ChangeNotifierProvider.value(value: desktop),
      ],
      child: Consumer2<LanguageProvider, AppearanceProvider>(
        builder: (context, language, appearance, _) => MaterialApp(
          title: 'QuickRemote PC',
          locale: language.language.locale,
          supportedLocales: supportedAppLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          debugShowCheckedModeBanner: false,
          // The system's light or dark, unless Settings picks one.
          themeMode: appearance.mode,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          navigatorKey: desktop.navigatorKey,
          builder: (context, child) {
            // The tray has no BuildContext; it takes the words from here.
            desktop.l10n = context.l10n;
            return MinSize(child: child!);
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
