import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/presentation_analytics.dart';

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
