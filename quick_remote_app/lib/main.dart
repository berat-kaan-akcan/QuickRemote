import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'services/websocket_service.dart';
import 'providers/settings_provider.dart';
import 'services/discovery_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
          colorSchemeSeed: const Color(0xFF6C63FF),
          useMaterial3: true,
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
