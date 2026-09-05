import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/presentation_analytics.dart';

class SettingsProvider extends ChangeNotifier {
  // Early Warning Haptic Feedback
  bool _earlyWarningHaptic = true;
  List<int> _warningTimes = [300, 60, 30]; // 5 min, 1 min, 30 sec

  // Presentation History
  List<PresentationAnalytics> _presentationHistory = [];
  static const int _maxHistoryCount = 20;
  static const String _historyKey = 'presentation_history';

  bool get earlyWarningHaptic => _earlyWarningHaptic;
  List<int> get warningTimes => _warningTimes;
  List<PresentationAnalytics> get presentationHistory =>
      List.unmodifiable(_presentationHistory);

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _earlyWarningHaptic = prefs.getBool('early_warning_haptic') ?? true;
    
    final timesStrList = prefs.getStringList('warning_times');
    if (timesStrList != null) {
      _warningTimes = timesStrList.map((e) => int.parse(e)).toList();
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

  Future<void> addWarningTime(int seconds) async {
    if (!_warningTimes.contains(seconds) && seconds > 0) {
      _warningTimes.add(seconds);
      _warningTimes.sort((a, b) => b.compareTo(a)); // Sort descending (e.g. 300, 60, 30)
      notifyListeners();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('warning_times', _warningTimes.map((e) => e.toString()).toList());
    }
  }

  Future<void> removeWarningTime(int seconds) async {
    if (_warningTimes.contains(seconds)) {
      _warningTimes.remove(seconds);
      notifyListeners();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('warning_times', _warningTimes.map((e) => e.toString()).toList());
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
