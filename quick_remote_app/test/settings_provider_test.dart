import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quick_remote_app/providers/settings_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('SettingsProvider initial values', () async {
    final provider = SettingsProvider();
    
    // allow microtasks to finish since _loadSettings is async
    await Future.delayed(Duration.zero);
    
    expect(provider.earlyWarningHaptic, true);
    expect(provider.warningVibrations, {
      300: 'double',
      60: 'double',
      30: 'double',
    });
    expect(provider.timeOutVibrationEnabled, true);
    expect(provider.timeOutVibrationPattern, 'triple');
    expect(provider.presentationHistory, isEmpty);
  });

  test('SettingsProvider updates early warning haptic', () async {
    final provider = SettingsProvider();
    await Future.delayed(Duration.zero);
    
    await provider.setEarlyWarningHaptic(false);
    expect(provider.earlyWarningHaptic, false);
    
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('early_warning_haptic'), false);
  });

  test('SettingsProvider adds and removes warning time', () async {
    final provider = SettingsProvider();
    await Future.delayed(Duration.zero);
    
    await provider.addWarningTime(120, pattern: 'single');
    expect(provider.warningVibrations[120], 'single');
    
    await provider.removeWarningTime(120);
    expect(provider.warningVibrations.containsKey(120), false);
  });
}
