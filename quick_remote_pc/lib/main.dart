import 'package:flutter/material.dart' hide Size;
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'dart:ui' as ui;
import 'screens/home/home_screen.dart';
import 'providers/server_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await windowManager.ensureInitialized();

  final windowOptions = WindowOptions(
    size: const ui.Size(420, 650),
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
}

class QuickRemotePC extends StatelessWidget {
  const QuickRemotePC({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => WebSocketServerProvider(),
      child: MaterialApp(
        title: 'QuickRemote PC',
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
