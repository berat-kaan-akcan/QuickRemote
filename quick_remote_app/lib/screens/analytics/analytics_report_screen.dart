import 'package:flutter/material.dart';
import '../../models/presentation_analytics.dart';
import '../../utils/formatters.dart';
import 'utils/report_exporter.dart';
import 'widgets/stat_card.dart';
import 'widgets/slide_duration_list.dart';
import '../../l10n/app_language.dart';
import '../../theme/app_colors.dart';

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
            color: AppColors.background,
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
                      colors: [AppColors.analyticsIndigo, AppColors.analyticsTeal],
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
                      Text(
                        context.l10n.reportTitle,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        Formatters.formatDate(analytics.startTime, context.l10n),
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
                  label: context.l10n.totalTime,
                  value: Formatters.formatDuration(analytics.totalDuration, context.l10n),
                  gradient: const [AppColors.analyticsIndigo, AppColors.analyticsIndigoDark],
                ),
                const SizedBox(width: 10),
                StatCard(
                  icon: Icons.layers_rounded,
                  label: context.l10n.slideCountLabel,
                  value: '${analytics.distinctSlideCount}',
                  gradient: const [AppColors.analyticsTeal, AppColors.analyticsTealDark],
                ),
                const SizedBox(width: 10),
                StatCard(
                  icon: Icons.speed_rounded,
                  label: context.l10n.avgPerSlideShort,
                  value: Formatters.formatDurationShort(analytics.averageTimePerSlide),
                  gradient: const [AppColors.analyticsCoral, AppColors.analyticsCoralDark],
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
                    context.l10n.totalTransitions(analytics.transitionCount),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  if (longest != null) ...[
                    Icon(Icons.arrow_upward_rounded,
                        color: AppColors.analyticsCoral, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'S${longest.key}: ${Formatters.formatDurationShort(longest.value)}',
                      style: const TextStyle(
                        color: AppColors.analyticsCoral,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  if (shortest != null && longest?.key != shortest.key) ...[
                    const SizedBox(width: 12),
                    Icon(Icons.arrow_downward_rounded,
                        color: AppColors.analyticsTeal, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'S${shortest.key}: ${Formatters.formatDurationShort(shortest.value)}',
                      style: const TextStyle(
                        color: AppColors.analyticsTeal,
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
              context.l10n.timePerSlide,
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
                    label: Text(context.l10n.copyToClipboard),
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
                    label: Text(context.l10n.ok),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.analyticsIndigo,
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
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            context.l10n.presentationDetails,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        body: content,
      );
    }

    return content;
  }
}
