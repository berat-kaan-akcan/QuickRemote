import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import '../../models/presentation_analytics.dart';
import '../../utils/formatters.dart';
import '../../utils/ui/app_dialog.dart';
import '../../utils/ui/app_snackbar.dart';
import '../analytics/analytics_report_screen.dart';
import '../../l10n/app_language.dart';
import '../../utils/ui/app_top_bar.dart';
import '../../widgets/status_view.dart';
import '../../widgets/ui/ui.dart';

class PresentationHistoryScreen extends StatelessWidget {
  const PresentationHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    final p = context.palette;
    return Scaffold(
      appBar: AppTopBar(
        title: context.l10n.settingsHistoryTitle,
        action: settings.presentationHistory.isEmpty
            ? null
            : AppTopBarAction(
                icon: Icons.delete_sweep_rounded,
                tooltip: context.l10n.clearHistory,
                onTap: () => _showClearHistoryDialog(context),
              ),
      ),
      body: ContentWidth(
        child: AnimatedSwitcher(
          duration: AppMotion.of(context, AppMotion.base),
          child: settings.presentationHistory.isEmpty
              ? Padding(
                  key: const ValueKey('empty'),
                  padding: const EdgeInsets.symmetric(horizontal: AppSpace.page),
                  child: StatusView(
                    icon: Icons.insights_rounded,
                    color: p.accentText,
                    title: context.l10n.noHistory,
                    message: context.l10n.noHistoryHint,
                  ),
                )
              : ListView(
                  key: const ValueKey('list'),
                  padding: EdgeInsets.fromLTRB(
                    AppSpace.page,
                    0,
                    AppSpace.page,
                    MediaQuery.paddingOf(context).bottom + AppSpace.xl,
                  ),
                  children: [
                    for (final (index, analytics) in settings.presentationHistory.indexed)
                      FadeSlideIn(
                        key: Key(analytics.id),
                        index: index,
                        child: _buildHistoryTile(context, analytics, index, settings),
                      ),
                    const SizedBox(height: AppSpace.xs),
                    Text(
                      context.l10n.historySwipeHint,
                      textAlign: TextAlign.center,
                      style: AppType.bodySmall.copyWith(color: p.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildHistoryTile(
    BuildContext context,
    PresentationAnalytics analytics,
    int index,
    SettingsProvider settings,
  ) {
    final p = context.palette;
    final meta = AppType.bodySmall.copyWith(color: p.textSecondary);
    // The gap below the card is inside the Dismissible, so the row shrinks
    // to nothing together with it (a gap outside stayed behind and jumped
    // away when the row left the list).
    return Dismissible(
      key: Key(analytics.id),
      direction: DismissDirection.endToStart,
      resizeDuration: AppMotion.of(context, AppMotion.base),
      movementDuration: AppMotion.of(context, AppMotion.base),
      background: Padding(
        padding: const EdgeInsets.only(bottom: AppSpace.sm),
        child: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: AppSpace.lg),
          decoration: BoxDecoration(
            color: p.danger.withValues(alpha: p.isDark ? 0.18 : 0.12),
            borderRadius: AppRadius.all(AppRadius.md),
            border: Border.all(color: p.danger.withValues(alpha: 0.35)),
          ),
          child: Icon(Icons.delete_rounded, color: p.danger),
        ),
      ),
      onDismissed: (_) {
        // Removed from the provider in this frame, so the dismissed row is
        // never built again.
        settings.deletePresentationAnalytics(analytics.id);
        AppSnackbar.show(
          context,
          message: context.l10n.historyDeleted,
          type: SnackbarType.success,
          duration: const Duration(seconds: 4),
          actionLabel: context.l10n.historyUndo,
          onAction: () => settings.restorePresentationAnalytics(analytics, index),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpace.sm),
        child: AppCard(
          radius: AppRadius.md,
          padding: const EdgeInsets.all(AppSpace.sm),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AnalyticsReportScreen(
                  analytics: analytics,
                  isFromHistory: true,
                ),
              ),
            );
          },
          child: Row(
            children: [
              IconBadge(icon: Icons.slideshow_rounded, color: p.primaryText, size: 44),
              const SizedBox(width: AppSpace.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      Formatters.formatDate(analytics.startTime, context.l10n),
                      style: AppType.titleSmall.copyWith(color: p.textPrimary, fontSize: 15),
                    ),
                    const SizedBox(height: 2),
                    Wrap(
                      spacing: AppSpace.md,
                      runSpacing: AppSpace.xxs,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.timer_outlined, size: 15, color: p.textMuted),
                            const SizedBox(width: AppSpace.xxs),
                            Text(Formatters.formatDuration(analytics.totalDuration, context.l10n), style: meta),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.layers_outlined, size: 15, color: p.textMuted),
                            const SizedBox(width: AppSpace.xxs),
                            Text(context.l10n.slideCount(analytics.distinctSlideCount), style: meta),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: p.textMuted),
            ],
          ),
        ),
      ),
    );
  }

  void _showClearHistoryDialog(BuildContext context) async {
    final confirmed = await AppDialog.showConfirm(
      context: context,
      title: context.l10n.clearHistory,
      content: context.l10n.clearHistoryContent,
      confirmText: context.l10n.clear,
    );

    if (confirmed && context.mounted) {
      context.read<SettingsProvider>().clearPresentationHistory();
      AppSnackbar.show(
        context,
        message: context.l10n.historyCleared,
        type: SnackbarType.success,
        duration: const Duration(seconds: 2),
      );
    }
  }
}
