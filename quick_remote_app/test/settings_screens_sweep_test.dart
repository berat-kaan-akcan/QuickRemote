import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:quick_remote_app/l10n/app_localizations.dart';
import 'package:quick_remote_app/providers/settings_provider.dart';
import 'package:quick_remote_app/screens/settings/capabilities_screen.dart';
import 'package:quick_remote_app/screens/settings/presentation_history_screen.dart';
import 'package:quick_remote_app/screens/settings/settings_screen.dart';
import 'package:quick_remote_app/screens/settings/theme_screen.dart';
import 'package:quick_remote_app/screens/settings/timer_settings_screen.dart';
import 'package:quick_remote_app/services/websocket_service.dart';
import 'package:quick_remote_app/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final screens = <String, Widget>{
    'settings': const SettingsScreen(),
    'theme': const ThemeScreen(),
    'timer': const TimerSettingsScreen(),
    'history': const PresentationHistoryScreen(),
    'capabilities': const CapabilitiesScreen(),
  };
  final sizes = {
    'phone 2.0': (const Size(360, 780), 2.0),
    'small phone 2.0': (const Size(320, 568), 2.0),
    'landscape': (const Size(780, 360), 1.0),
    'tablet': (const Size(800, 1280), 1.0),
  };
  for (final lang in ['tr', 'en']) {
    for (final e in screens.entries) {
      for (final s in sizes.entries) {
        testWidgets('${e.key} ($lang) at ${s.key}: no overflow, 48 dp targets, labels', (tester) async {
          SharedPreferences.setMockInitialValues({});
          tester.view.physicalSize = s.value.$1;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          final handle = tester.ensureSemantics();
          await tester.pumpWidget(MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => SettingsProvider()),
              ChangeNotifierProvider(create: (_) => WebSocketService()),
            ],
            child: MaterialApp(
              theme: AppTheme.dark,
              locale: Locale(lang),
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              builder: (c, child) => MediaQuery(
                data: MediaQuery.of(c).copyWith(textScaler: TextScaler.linear(s.value.$2)),
                child: child!,
              ),
              home: e.value,
            ),
          ));
          await tester.pump(const Duration(seconds: 1));
          expect(tester.takeException(), isNull);
          await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
          await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
          handle.dispose();
        });
      }
    }
  }
}
