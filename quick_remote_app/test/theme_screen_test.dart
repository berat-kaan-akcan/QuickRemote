import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:quick_remote_app/l10n/app_localizations.dart';
import 'package:quick_remote_app/providers/settings_provider.dart';
import 'package:quick_remote_app/screens/settings/theme_screen.dart';
import 'package:quick_remote_app/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<SettingsProvider> pumpScreen(WidgetTester tester) async {
    final settings = SettingsProvider();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: settings,
        child: MaterialApp(
          theme: AppTheme.dark,
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const ThemeScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return settings;
  }

  testWidgets('the watch switch is on by default, says Sunset is Cobalt there, and turns off', (tester) async {
    tester.view.physicalSize = const Size(1080, 4000);
    addTearDown(tester.view.reset);
    final settings = await pumpScreen(tester);

    expect(find.text('Use on the watch too'), findsOneWidget);
    expect(find.text('The watch is always dark: Sunset shows as Cobalt there.'), findsOneWidget);
    expect(settings.watchUsesTheme, isTrue);
    expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);

    await tester.tap(find.text('Use on the watch too'));
    await tester.pumpAndSettle();
    expect(settings.watchUsesTheme, isFalse);
    expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('watch_uses_theme'), isFalse);
  });
}
