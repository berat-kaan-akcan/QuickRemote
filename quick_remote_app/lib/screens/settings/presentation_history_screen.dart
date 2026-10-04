import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import '../../models/presentation_analytics.dart';
import '../../utils/formatters.dart';
import '../../utils/ui/app_dialog.dart';
import '../../utils/ui/app_snackbar.dart';
import '../analytics/analytics_report_screen.dart';
import '../../l10n/app_language.dart';
import '../../widgets/ui/ui.dart';

class PresentationHistoryScreen extends StatelessWidget {
  const PresentationHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.settingsHistoryTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (settings.presentationHistory.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded),
              tooltip: context.l10n.clearHistory,
              onPressed: () => _showClearHistoryDialog(context),
            ),
          const SizedBox(width: AppSpace.xxs),
        ],
      ),
      body: ContentWidth(
        child: AnimatedSwitcher(
          duration: AppMotion.of(context, AppMotion.base),
          child: settings.presentationHistory.isEmpty
              ? Center(
                  key: const ValueKey('empty'),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpace.xl),
                    child: FadeSlideIn(
                      child: EmptyState(
                        icon: Icons.insights_rounded,
                        tone: AppTone.accent,
                        title: context.l10n.noHistory,
                        message: context.l10n.noHistoryHint,
                      ),
                    ),
                  ),
                )
              : ListView.builder(
                  key: const ValueKey('list'),
                  padding: EdgeInsets.fromLTRB(
                    AppSpace.page,
                    AppSpace.sm,
                    AppSpace.page,
                    MediaQuery.paddingOf(context).bottom + AppSpace.xl,
                  ),
                  itemCount: settings.presentationHistory.length,
                  itemBuilder: (context, index) {
                    final analytics = settings.presentationHistory[index];
                    return FadeSlideIn(
                      key: Key(analytics.id),
                      index: index,
                      child: _buildHistoryTile(context, analytics, settings),
                    );
                  },
                ),
        ),
      ),
    );
  }

  Widget _buildHistoryTile(BuildContext context, PresentationAnalytics analytics, SettingsProvider settings) {
    final p = context.palette;
    final meta = AppType.bodySmall.copyWith(color: p.textSecondary);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.sm),
      child: Dismissible(
        key: Key(analytics.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: AppSpace.lg),
          decoration: BoxDecoration(
            color: p.danger.withValues(alpha: p.isDark ? 0.18 : 0.12),
            borderRadius: AppRadius.all(AppRadius.lg),
            border: Border.all(color: p.danger.withValues(alpha: 0.35)),
          ),
          child: Icon(Icons.delete_rounded, color: p.danger),
        ),
        onDismissed: (_) {
          settings.deletePresentationAnalytics(analytics.id);
          AppSnackbar.show(
            context,
            message: context.l10n.historyDeleted,
            type: SnackbarType.success,
            duration: const Duration(seconds: 2),
          );
        },
        child: AppCard(
          padding: const EdgeInsets.all(AppSpace.md),
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
              IconBadge(icon: Icons.slideshow_rounded, color: p.primaryText, size: 48),
              const SizedBox(width: AppSpace.md - 2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      Formatters.formatDate(analytics.startTime, context.l10n),
                      style: AppType.titleSmall.copyWith(color: p.textPrimary),
                    ),
                    const SizedBox(height: 6),
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
