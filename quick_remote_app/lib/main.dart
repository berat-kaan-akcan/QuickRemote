import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_background/flutter_background.dart';
import 'screens/home_screen.dart';
import 'services/websocket_service.dart';
import 'providers/settings_provider.dart';
import 'services/discovery_service.dart';

import 'package:permission_handler/permission_handler.dart';

Future<void> initBackground() async {
  // Check and request notification permissions
  if (await Permission.notification.isDenied) {
    await Permission.notification.request();
  }

  // Check and request ignore battery optimizations (important for background services)
  if (await Permission.ignoreBatteryOptimizations.isDenied) {
    await Permission.ignoreBatteryOptimizations.request();
  }

  const androidConfig = FlutterBackgroundAndroidConfig(
    notificationTitle: "QuickRemote",
    notificationText: "Arka planda bağlantı devam ediyor...",
    notificationImportance: AndroidNotificationImportance.normal,
    notificationIcon: AndroidResource(name: 'ic_launcher', defType: 'mipmap'),
  );
  
  bool success = await FlutterBackground.initialize(androidConfig: androidConfig);
  if (success) {
    await FlutterBackground.enableBackgroundExecution();
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await initBackground();
  } catch (e) {
    debugPrint('Background init error: $e');
  }
  runApp(const QuickRemoteApp());
}

class QuickRemoteApp extends StatelessWidget {
  const QuickRemoteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => WebSocketService()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
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
          textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
