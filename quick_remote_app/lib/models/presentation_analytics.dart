// Model classes for presentation analytics tracking.
// Stores per-slide timing data and provides aggregate statistics.

class SlideRecord {
  final int slideNumber;
  final DateTime enteredAt;
  DateTime? exitedAt;

  SlideRecord({
    required this.slideNumber,
    required this.enteredAt,
    this.exitedAt,
  });

  Duration get duration =>
      (exitedAt ?? DateTime.now()).difference(enteredAt);

  Map<String, dynamic> toJson() => {
        'slideNumber': slideNumber,
        'enteredAt': enteredAt.toIso8601String(),
        'exitedAt': exitedAt?.toIso8601String(),
      };

  factory SlideRecord.fromJson(Map<String, dynamic> json) => SlideRecord(
        slideNumber: json['slideNumber'] as int,
        enteredAt: DateTime.parse(json['enteredAt'] as String),
        exitedAt: json['exitedAt'] != null
            ? DateTime.parse(json['exitedAt'] as String)
            : null,
      );
}

class PresentationAnalytics {
  final String id;
  final DateTime startTime;
  DateTime? endTime;
  final int totalSlideCount;
  final List<SlideRecord> slideRecords;

  PresentationAnalytics({
    required this.id,
    required this.startTime,
    this.endTime,
    required this.totalSlideCount,
    List<SlideRecord>? slideRecords,
  }) : slideRecords = slideRecords ?? [];

  /// Total presentation duration.
  Duration get totalDuration =>
      (endTime ?? DateTime.now()).difference(startTime);

  /// Aggregate time spent on each unique slide number.
  /// A slide visited multiple times has its durations summed.
  Map<int, Duration> get timePerSlide {
    final map = <int, Duration>{};
    for (final record in slideRecords) {
      final current = map[record.slideNumber] ?? Duration.zero;
      map[record.slideNumber] = current + record.duration;
    }
    return map;
  }

  /// Number of distinct slides visited.
  int get distinctSlideCount => timePerSlide.keys.length;

  /// The slide where the most time was spent.
  MapEntry<int, Duration>? get longestSlide {
    final tps = timePerSlide;
    if (tps.isEmpty) return null;
    return tps.entries.reduce((a, b) => a.value >= b.value ? a : b);
  }

  /// The slide where the least time was spent.
  MapEntry<int, Duration>? get shortestSlide {
    final tps = timePerSlide;
    if (tps.isEmpty) return null;
    return tps.entries.reduce((a, b) => a.value <= b.value ? a : b);
  }

  /// Average time per distinct slide.
  Duration get averageTimePerSlide {
    final tps = timePerSlide;
    if (tps.isEmpty) return Duration.zero;
    final totalMs =
        tps.values.fold<int>(0, (sum, d) => sum + d.inMilliseconds);
    return Duration(milliseconds: totalMs ~/ tps.length);
  }

  /// Total number of slide transitions (forward + backward).
  int get transitionCount =>
      slideRecords.length > 1 ? slideRecords.length - 1 : 0;

  Map<String, dynamic> toJson() => {
        'id': id,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime?.toIso8601String(),
        'totalSlideCount': totalSlideCount,
        'slideRecords': slideRecords.map((r) => r.toJson()).toList(),
      };

  factory PresentationAnalytics.fromJson(Map<String, dynamic> json) =>
      PresentationAnalytics(
        id: json['id'] as String,
        startTime: DateTime.parse(json['startTime'] as String),
        endTime: json['endTime'] != null
            ? DateTime.parse(json['endTime'] as String)
            : null,
        totalSlideCount: json['totalSlideCount'] as int? ?? 0,
        slideRecords: (json['slideRecords'] as List<dynamic>?)
                ?.map((e) =>
                    SlideRecord.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );
}
