import 'package:flutter/material.dart';
import '../../models/presentation_analytics.dart';
import '../../utils/formatters.dart';
import 'utils/report_exporter.dart';
import 'widgets/stat_card.dart';
import 'widgets/slide_duration_list.dart';
import '../../l10n/app_language.dart';
import '../../utils/ui/app_popup_theme.dart';
import '../../widgets/ui/ui.dart';

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
      constraints: const BoxConstraints(maxWidth: AppSpace.contentMaxWidth),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, scrollController) => Container(
          decoration: BoxDecoration(
            color: ctx.palette.background,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
            border: Border(top: BorderSide(color: ctx.palette.glassBorder)),
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
    final p = context.palette;
    final longest = analytics.longestSlide;
    final shortest = analytics.shortestSlide;

    Widget content = CustomScrollView(
      slivers: [
        // Handle bar (for bottom sheet mode)
        if (!isFromHistory)
          SliverToBoxAdapter(
            child: Center(
              child: Container(
                margin: const EdgeInsets.only(top: AppSpace.sm, bottom: AppSpace.xs),
                width: AppPopupTheme.handleWidth,
                height: AppPopupTheme.handleHeight,
                decoration: BoxDecoration(
                  color: p.borderStrong,
                  borderRadius: AppRadius.all(AppRadius.pill),
                ),
              ),
            ),
          ),

        // Title
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpace.page, AppSpace.md, AppSpace.page, AppSpace.xs),
            child: FadeSlideIn(
              child: Row(
                children: [
                  IconBadge(icon: Icons.insights_rounded, color: p.primary, size: 48, filled: true),
                  const SizedBox(width: AppSpace.md - 2),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.l10n.reportTitle,
                          style: AppType.headline.copyWith(color: p.textPrimary, fontSize: 22),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          Formatters.formatDate(analytics.startTime, context.l10n),
                          style: AppType.bodySmall.copyWith(color: p.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Stats cards
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpace.page, AppSpace.md, AppSpace.page, AppSpace.xs),
            child: FadeSlideIn(
              index: 1,
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    StatCard(
                      icon: Icons.timer_rounded,
                      label: context.l10n.totalTime,
                      value: Formatters.formatDuration(analytics.totalDuration, context.l10n),
                      color: p.primaryText,
                    ),
                    const SizedBox(width: AppSpace.xs + 2),
                    StatCard(
                      icon: Icons.layers_rounded,
                      label: context.l10n.slideCountLabel,
                      value: '${analytics.distinctSlideCount}',
                      color: p.info,
                    ),
                    const SizedBox(width: AppSpace.xs + 2),
                    StatCard(
                      icon: Icons.speed_rounded,
                      label: context.l10n.avgPerSlideShort,
                      value: Formatters.formatDurationShort(analytics.averageTimePerSlide),
                      color: p.accentText,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Transition count
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpace.page, AppSpace.xs, AppSpace.page, AppSpace.md),
            child: FadeSlideIn(
              index: 2,
              child: AppCard(
                padding: const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: AppSpace.sm),
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: AppSpace.md,
                  runSpacing: AppSpace.xs,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.swap_horiz_rounded, color: p.textSecondary, size: 20),
                        const SizedBox(width: AppSpace.xs),
                        Text(
                          context.l10n.totalTransitions(analytics.transitionCount),
                          style: AppType.body.copyWith(color: p.textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    if (longest != null)
                      _ExtremeChip(
                        icon: Icons.arrow_upward_rounded,
                        color: p.accentText,
                        text: 'S${longest.key}: ${Formatters.formatDurationShort(longest.value)}',
                      ),
                    if (shortest != null && longest?.key != shortest.key)
                      _ExtremeChip(
                        icon: Icons.arrow_downward_rounded,
                        color: p.success,
                        text: 'S${shortest.key}: ${Formatters.formatDurationShort(shortest.value)}',
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Section header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpace.page, AppSpace.xs, AppSpace.page, AppSpace.xxs),
            child: SectionHeader(title: context.l10n.timePerSlide, icon: Icons.bar_chart_rounded),
          ),
        ),

        // Slide bars List
        SlideDurationList(analytics: analytics),

        // Bottom actions
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpace.page,
              AppSpace.xl,
              AppSpace.page,
              MediaQuery.paddingOf(context).bottom + AppSpace.xl,
            ),
            child: Column(
              children: [
                AppButton(
                  label: context.l10n.ok,
                  icon: Icons.check_rounded,
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const SizedBox(height: AppSpace.xs),
                AppButton(
                  label: context.l10n.copyToClipboard,
                  icon: Icons.copy_rounded,
                  variant: AppButtonVariant.outline,
                  tone: AppTone.neutral,
                  onPressed: () => ReportExporter.copyToClipboard(context, analytics),
                ),
              ],
            ),
          ),
        ),
      ],
    );

    if (isFromHistory) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(context.l10n.presentationDetails),
        ),
        body: ContentWidth(child: content),
      );
    }

    return content;
  }
}

/// The longest or shortest slide in the summary row.
class _ExtremeChip extends StatelessWidget {
  const _ExtremeChip({required this.icon, required this.color, required this.text});

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.xs, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: p.isDark ? 0.14 : 0.10),
        borderRadius: AppRadius.all(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(text, style: AppType.mono.copyWith(color: color, fontWeight: FontWeight.w700, fontSize: 12)),
        ],
      ),
    );
  }
}
