import 'package:flutter/material.dart';
import '../models/presentation_analytics.dart';
import '../utils/formatters.dart';
import 'analytics/utils/report_exporter.dart';
import 'analytics/widgets/stat_card.dart';
import 'analytics/widgets/slide_duration_list.dart';

/// A premium-looking analytics report screen that displays
/// per-slide timing data and aggregate statistics.
/// Can be shown as a full screen (from history) or bottom sheet (after presentation).
class AnalyticsReportScreen extends StatelessWidget {
  final PresentationAnalytics analytics;
  final bool isFromHistory;

  const AnalyticsReportScreen({
    super.key,
    required this.analytics,
    this.isFromHistory = false,
  });

  /// Show as a modal bottom sheet (used after presentation ends).
  static Future<void> showAsBottomSheet(
    BuildContext context,
    PresentationAnalytics analytics,
  ) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFF0D0D1A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: AnalyticsReportScreen(
            analytics: analytics,
            isFromHistory: false,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final longest = analytics.longestSlide;
    final shortest = analytics.shortestSlide;

    Widget content = CustomScrollView(
      slivers: [
        // Handle bar (for bottom sheet mode)
        if (!isFromHistory)
          SliverToBoxAdapter(
            child: Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),

        // Title
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6C63FF), Color(0xFF4ECDC4)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.analytics_rounded, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Sunum Raporu',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        Formatters.formatDate(analytics.startTime),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Stats cards
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                StatCard(
                  icon: Icons.timer_rounded,
                  label: 'Toplam Süre',
                  value: Formatters.formatDuration(analytics.totalDuration),
                  gradient: const [Color(0xFF6C63FF), Color(0xFF5A54E0)],
                ),
                const SizedBox(width: 10),
                StatCard(
                  icon: Icons.layers_rounded,
                  label: 'Slayt Sayısı',
                  value: '${analytics.distinctSlideCount}',
                  gradient: const [Color(0xFF4ECDC4), Color(0xFF3DBDB5)],
                ),
                const SizedBox(width: 10),
                StatCard(
                  icon: Icons.speed_rounded,
                  label: 'Ort/Slayt',
                  value: Formatters.formatDurationShort(analytics.averageTimePerSlide),
                  gradient: const [Color(0xFFFF6B6B), Color(0xFFE05555)],
                ),
              ],
            ),
          ),
        ),

        // Transition count
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Row(
                children: [
                  Icon(Icons.swap_horiz_rounded,
                      color: Colors.white.withValues(alpha: 0.6), size: 20),
                  const SizedBox(width: 10),
                  Text(
                    'Toplam Geçiş: ${analytics.transitionCount}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  if (longest != null) ...[
                    Icon(Icons.arrow_upward_rounded,
                        color: const Color(0xFFFF6B6B), size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'S${longest.key}: ${Formatters.formatDurationShort(longest.value)}',
                      style: const TextStyle(
                        color: Color(0xFFFF6B6B),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  if (shortest != null && longest?.key != shortest.key) ...[
                    const SizedBox(width: 12),
                    Icon(Icons.arrow_downward_rounded,
                        color: const Color(0xFF4ECDC4), size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'S${shortest.key}: ${Formatters.formatDurationShort(shortest.value)}',
                      style: const TextStyle(
                        color: Color(0xFF4ECDC4),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),

        // Section header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Text(
              'Slayt Bazlı Süre',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),

        // Slide bars List
        SlideDurationList(analytics: analytics),

        // Bottom actions
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => ReportExporter.copyToClipboard(context, analytics),
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    label: const Text('Panoya Kopyala'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text('Tamam'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF6C63FF),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );

    if (isFromHistory) {
      return Scaffold(
        backgroundColor: const Color(0xFF0D0D1A),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text(
            'Sunum Detayı',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        body: content,
      );
    }

    return content;
  }
}
