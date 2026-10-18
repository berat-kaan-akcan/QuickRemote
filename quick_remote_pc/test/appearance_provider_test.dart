import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quick_remote_pc/providers/appearance_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('follows the system until a mode is picked', () async {
    final provider = AppearanceProvider();
    await Future.delayed(Duration.zero);
    expect(provider.mode, ThemeMode.system);
  });

  test('stores the picked mode, system clears it', () async {
    await AppearanceProvider().setMode(ThemeMode.light);
    final reloaded = AppearanceProvider();
    await Future.delayed(Duration.zero);
    expect(reloaded.mode, ThemeMode.light);

    await reloaded.setMode(ThemeMode.system);
    final cleared = AppearanceProvider();
    await Future.delayed(Duration.zero);
    expect(cleared.mode, ThemeMode.system);
  });
}
