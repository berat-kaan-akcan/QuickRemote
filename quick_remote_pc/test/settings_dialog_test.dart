import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:quick_remote_pc/l10n/app_language.dart';
import 'package:quick_remote_pc/providers/language_provider.dart';
import 'package:quick_remote_pc/screens/home/widgets/settings_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _app(LanguageProvider language) => ChangeNotifierProvider.value(
      value: language,
      child: Consumer<LanguageProvider>(
        builder: (context, language, _) => MaterialApp(
          locale: language.language.locale,
          supportedLocales: supportedAppLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const Scaffold(body: SettingsDialog()),
        ),
      ),
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('picking a language switches the UI at once', (tester) async {
    final language = LanguageProvider();
    await language.setLanguage(AppLanguage.tr);
    await tester.pumpWidget(_app(language));
    await tester.pumpAndSettle();
    expect(find.text('Ayarlar'), findsOneWidget);

    await tester.tap(find.byType(DropdownButton<AppLanguage>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('English').last);
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsOneWidget);
    expect(language.language, AppLanguage.en);
  });
}
