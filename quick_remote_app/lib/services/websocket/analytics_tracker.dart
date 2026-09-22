import 'package:flutter/foundation.dart';
import '../../models/presentation_analytics.dart';

class AnalyticsTracker {
  PresentationAnalytics? _analytics;
  bool _isTracking = false;
  PresentationAnalytics? _completedAnalytics;

  bool get isTracking => _isTracking;
  PresentationAnalytics? get analytics => _analytics;
  PresentationAnalytics? get completedAnalytics => _completedAnalytics;

  void clearCompletedAnalytics() {
    _completedAnalytics = null;
  }

  void startTracking(int totalSlides, int currentSlide) {
    final now = DateTime.now();
    _analytics = PresentationAnalytics(
      id: now.toIso8601String(),
      startTime: now,
      totalSlideCount: totalSlides,
    );
    _isTracking = true;

    if (currentSlide > 0) {
      _analytics!.slideRecords.add(SlideRecord(
        slideNumber: currentSlide,
        enteredAt: now,
      ));
    }
    debugPrint('Analytics: tracking started');
  }

  PresentationAnalytics? stopTracking(int totalSlides) {
    if (!_isTracking || _analytics == null) return null;

    final now = DateTime.now();
    if (_analytics!.slideRecords.isNotEmpty) {
      final last = _analytics!.slideRecords.last;
      last.exitedAt ??= now;
    }
    _analytics!.endTime = now;
    _analytics = PresentationAnalytics(
      id: _analytics!.id,
      startTime: _analytics!.startTime,
      endTime: now,
      totalSlideCount: totalSlides > 0 ? totalSlides : _analytics!.totalSlideCount,
      slideRecords: _analytics!.slideRecords,
    );
    _isTracking = false;

    debugPrint('Analytics: tracking stopped, ${_analytics!.slideRecords.length} records');
    return _analytics;
  }

  void autoStopTracking(int totalSlides) {
    if (!_isTracking || _analytics == null) return;
    final result = stopTracking(totalSlides);
    if (result != null && result.slideRecords.isNotEmpty) {
      _completedAnalytics = result;
      debugPrint('Analytics: auto-stopped, ready for UI pickup');
    }
  }

  void recordSlideChange(int newSlide, int currentSlide) {
    if (_isTracking && _analytics != null && newSlide != currentSlide && newSlide > 0) {
      final now = DateTime.now();
      if (_analytics!.slideRecords.isNotEmpty) {
        final last = _analytics!.slideRecords.last;
        last.exitedAt ??= now;
      }
      _analytics!.slideRecords.add(SlideRecord(
        slideNumber: newSlide,
        enteredAt: now,
      ));
      debugPrint('Analytics: slide $newSlide entered');
    }
  }
}
