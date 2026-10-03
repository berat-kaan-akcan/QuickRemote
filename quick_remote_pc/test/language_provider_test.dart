import 'package:flutter_test/flutter_test.dart';
import 'package:quick_remote_pc/l10n/app_language.dart';
import 'package:quick_remote_pc/providers/language_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('follows the system until a language is picked', () async {
    final provider = LanguageProvider();
    await Future.delayed(Duration.zero);
    expect(provider.language, AppLanguage.system);
    expect(provider.language.locale, isNull);
  });

  test('stores the picked language, system clears it', () async {
    await LanguageProvider().setLanguage(AppLanguage.en);
    final reloaded = LanguageProvider();
    await Future.delayed(Duration.zero);
    expect(reloaded.language, AppLanguage.en);

    await reloaded.setLanguage(AppLanguage.system);
    final cleared = LanguageProvider();
    await Future.delayed(Duration.zero);
    expect(cleared.language, AppLanguage.system);
  });
}
