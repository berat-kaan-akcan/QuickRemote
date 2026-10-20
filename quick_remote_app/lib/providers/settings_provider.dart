import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/presentation_analytics.dart';
import '../l10n/app_language.dart';
import '../services/bluetooth/bt_key_mapping.dart';
import '../theme/app_color_theme.dart';

class SettingsProvider extends ChangeNotifier {
  // Early Warning Haptic Feedback
  bool _earlyWarningHaptic = true;
  Map<int, String> _warningVibrations = {
    300: 'double',
    60: 'double',
    30: 'double',
  };
  
  bool _timeOutVibrationEnabled = true;
  String _timeOutVibrationPattern = 'triple';

  // Start the presentation timer as soon as a duration is picked
  bool _timerAutoStart = false;

  // The talk's length in seconds, 0 for none: picked on the phone's timer or
  // on the watch, and shared by both
  int _talkDuration = 0;

  // Presentation program targeted in Bluetooth HID mode
  BtTarget _btTarget = BtTarget.powerpoint;

  // Keep pen ink on its slide when the slide changes (sent to the PC)
  bool _keepInkOnSlideChange = false;

  // The slide's picture on the remote (sent to the PC)
  bool _slidePreview = true;

  // UI language; system follows the phone (not sent to the PC)
  AppLanguage _language = AppLanguage.system;

  // Color theme, and Cobalt's light/dark mode (the other themes have one look)
  AppColorTheme _colorTheme = AppColorTheme.cobalt;
  ThemeMode _themeMode = ThemeMode.system;

  // The color theme goes to the watch too (Sunset, light only, as Cobalt)
  bool _watchUsesTheme = true;

  // The program the user marked per PC (its address) in the remote's program
  // sheet. It only names the program while no show runs; the PC is not told.
  Map<String, String> _presenterByPc = {};

  // Presentation History
  List<PresentationAnalytics> _presentationHistory = [];
  static const int _maxHistoryCount = 20;
  static const String _historyKey = 'presentation_history';

  bool get earlyWarningHaptic => _earlyWarningHaptic;
  Map<int, String> get warningVibrations => _warningVibrations;
  List<int> get warningTimes {
    final times = _warningVibrations.keys.toList();
    times.sort((a, b) => b.compareTo(a));
    return times;
  }
  bool get timeOutVibrationEnabled => _timeOutVibrationEnabled;
  String get timeOutVibrationPattern => _timeOutVibrationPattern;
  bool get timerAutoStart => _timerAutoStart;
  int get talkDuration => _talkDuration;
  BtTarget get btTarget => _btTarget;
  bool get keepInkOnSlideChange => _keepInkOnSlideChange;
  bool get slidePreview => _slidePreview;
  AppLanguage get language => _language;
  AppColorTheme get colorTheme => _colorTheme;
  ThemeMode get themeMode => _themeMode;
  bool get watchUsesTheme => _watchUsesTheme;

  /// The mode the app is in: Cobalt's choice, or the theme's own look.
  ThemeMode get effectiveThemeMode => _colorTheme.followsMode ? _themeMode : _colorTheme.fixedMode;
  String? presenterFor(String pc) => _presenterByPc[pc];
  List<PresentationAnalytics> get presentationHistory =>
      List.unmodifiable(_presentationHistory);

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _earlyWarningHaptic = prefs.getBool('early_warning_haptic') ?? true;
    _timeOutVibrationEnabled = prefs.getBool('timeout_vibration_enabled') ?? true;
    _timeOutVibrationPattern = prefs.getString('timeout_vibration_pattern') ?? 'triple';
    _timerAutoStart = prefs.getBool('timer_auto_start') ?? false;
    _talkDuration = prefs.getInt('talk_duration') ?? 0;
    _btTarget = BtTarget.fromName(prefs.getString('bt_target'));
    _keepInkOnSlideChange = prefs.getBool('keep_ink_on_slide_change') ?? false;
    _slidePreview = prefs.getBool('slide_preview') ?? true;
    _language = AppLanguage.fromCode(prefs.getString('language'));
    _colorTheme = AppColorTheme.fromName(prefs.getString('color_theme'));
    _themeMode = ThemeMode.values.firstWhere(
      (m) => m.name == prefs.getString('theme_mode'),
      orElse: () => ThemeMode.system,
    );
    _watchUsesTheme = prefs.getBool('watch_uses_theme') ?? true;
    final presenters = prefs.getString('presenter_by_pc');
    if (presenters != null) {
      try {
        _presenterByPc = (jsonDecode(presenters) as Map<String, dynamic>).map((k, v) => MapEntry(k, v as String));
      } catch (e) {
        _presenterByPc = {};
      }
    }
    
    final timesStrList = prefs.getStringList('warning_times');
    final vibrationsStr = prefs.getString('warning_vibrations');
    
    if (vibrationsStr != null) {
      try {
        final decoded = jsonDecode(vibrationsStr) as Map<String, dynamic>;
        _warningVibrations = decoded.map((key, value) => MapEntry(int.parse(key), value as String));
      } catch (e) {
        debugPrint('Failed to parse warning vibrations: $e');
      }
    } else if (timesStrList != null) {
      _warningVibrations = {};
      for (var time in timesStrList) {
        _warningVibrations[int.parse(time)] = 'double';
      }
    }

    // Load presentation history
    final historyJson = prefs.getString(_historyKey);
    if (historyJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(historyJson) as List<dynamic>;
        _presentationHistory = decoded
            .map((e) =>
                PresentationAnalytics.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (e) {
        debugPrint('Failed to load presentation history: $e');
        _presentationHistory = [];
      }
    }
    
    notifyListeners();
  }

  Future<void> setEarlyWarningHaptic(bool value) async {
    _earlyWarningHaptic = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('early_warning_haptic', value);
  }

  Future<void> addWarningTime(int seconds, {String pattern = 'double'}) async {
    if (seconds > 0) {
      _warningVibrations[seconds] = pattern;
      notifyListeners();
      await _persistVibrations();
    }
  }

  Future<void> updateWarningPattern(int seconds, String pattern) async {
    if (_warningVibrations.containsKey(seconds)) {
      _warningVibrations[seconds] = pattern;
      notifyListeners();
      await _persistVibrations();
    }
  }

  Future<void> removeWarningTime(int seconds) async {
    if (_warningVibrations.containsKey(seconds)) {
      _warningVibrations.remove(seconds);
      notifyListeners();
      await _persistVibrations();
    }
  }
  
  Future<void> _persistVibrations() async {
    final prefs = await SharedPreferences.getInstance();
    final stringMap = _warningVibrations.map((key, value) => MapEntry(key.toString(), value));
    await prefs.setString('warning_vibrations', jsonEncode(stringMap));
    // For backward compatibility just in case
    await prefs.setStringList('warning_times', _warningVibrations.keys.map((e) => e.toString()).toList());
  }

  Future<void> setTimeOutVibrationEnabled(bool value) async {
    _timeOutVibrationEnabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('timeout_vibration_enabled', value);
  }

  Future<void> setTimeOutVibrationPattern(String pattern) async {
    _timeOutVibrationPattern = pattern;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('timeout_vibration_pattern', pattern);
  }

  Future<void> setTimerAutoStart(bool value) async {
    _timerAutoStart = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('timer_auto_start', value);
  }

  Future<void> setTalkDuration(int seconds) async {
    if (seconds < 0 || seconds == _talkDuration) return;
    _talkDuration = seconds;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('talk_duration', seconds);
  }

  Future<void> setBtTarget(BtTarget target) async {
    _btTarget = target;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('bt_target', target.name);
  }

  Future<void> setKeepInkOnSlideChange(bool value) async {
    _keepInkOnSlideChange = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('keep_ink_on_slide_change', value);
  }

  Future<void> setSlidePreview(bool value) async {
    _slidePreview = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('slide_preview', value);
  }

  Future<void> setColorTheme(AppColorTheme theme) async {
    _colorTheme = theme;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('color_theme', theme.name);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', mode.name);
  }

  Future<void> setWatchUsesTheme(bool value) async {
    _watchUsesTheme = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('watch_uses_theme', value);
  }

  Future<void> setPresenterFor(String pc, String presenter) async {
    _presenterByPc = {..._presenterByPc, pc: presenter};
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('presenter_by_pc', jsonEncode(_presenterByPc));
  }

  Future<void> setLanguage(AppLanguage language) async {
    _language = language;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    final code = language.code;
    if (code == null) {
      await prefs.remove('language');
    } else {
      await prefs.setString('language', code);
    }
  }

  // ─── Presentation History Management ───

  /// Save a completed presentation analytics record.
  /// Keeps at most [_maxHistoryCount] entries (oldest are removed).
  Future<void> savePresentationAnalytics(PresentationAnalytics analytics) async {
    _presentationHistory.insert(0, analytics); // Newest first

    // Trim to max count
    if (_presentationHistory.length > _maxHistoryCount) {
      _presentationHistory =
          _presentationHistory.sublist(0, _maxHistoryCount);
    }

    notifyListeners();
    await _persistHistory();
  }

  /// Delete a single presentation record by ID.
  Future<void> deletePresentationAnalytics(String id) async {
    _presentationHistory.removeWhere((a) => a.id == id);
    notifyListeners();
    await _persistHistory();
  }

  /// Clear all presentation history.
  Future<void> clearPresentationHistory() async {
    _presentationHistory.clear();
    notifyListeners();
    await _persistHistory();
  }

  /// Persist history list to SharedPreferences as JSON.
  Future<void> _persistHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _presentationHistory.map((a) => a.toJson()).toList();
    await prefs.setString(_historyKey, jsonEncode(jsonList));
  }
}
