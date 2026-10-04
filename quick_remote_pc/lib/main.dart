import 'package:flutter/material.dart' hide Size;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'l10n/app_language.dart';
import 'screens/home/home_screen.dart';
import 'providers/language_provider.dart';
import 'providers/server_provider.dart';
import 'services/linux/desktop_entry.dart';
import 'theme/app_colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _registerFontLicense();

  await windowManager.ensureInitialized();

  final windowOptions = WindowOptions(
    size: const ui.Size(420, 700),
    minimumSize: const ui.Size(380, 550),
    center: true,
    title: 'QuickRemote PC',
    titleBarStyle: TitleBarStyle.normal,
  );

  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(const QuickRemotePC());

  // Gives the window its icon in the taskbar (Wayland finds it by app id).
  if (Platform.isLinux) DesktopEntry.ensureInstalled();
}

class QuickRemotePC extends StatelessWidget {
  const QuickRemotePC({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => WebSocketServerProvider()),
      ],
      child: Consumer<LanguageProvider>(
        builder: (context, language, _) => MaterialApp(
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
          themeMode: ThemeMode.dark,
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: AppColors.background, // Deep Space Black
            colorSchemeSeed: AppColors.primary,
            useMaterial3: true,
            fontFamily: 'Inter',
          ),
          home: const HomeScreen(),
        ),
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
