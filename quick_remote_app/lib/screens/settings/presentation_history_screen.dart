import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import '../../models/presentation_analytics.dart';
import '../../utils/formatters.dart';
import '../../utils/ui/app_dialog.dart';
import '../../utils/ui/app_snackbar.dart';
import '../analytics/analytics_report_screen.dart';
import '../../l10n/app_language.dart';
import '../../theme/app_colors.dart';

class PresentationHistoryScreen extends StatelessWidget {
  const PresentationHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(context.l10n.settingsHistoryTitle, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (settings.presentationHistory.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.white70),
              tooltip: context.l10n.clearHistory,
              onPressed: () => _showClearHistoryDialog(context),
            ),
        ],
      ),
      body: settings.presentationHistory.isEmpty
          ? Center(
              child: Container(
                padding: const EdgeInsets.all(32),
                margin: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.analytics_outlined, size: 48, color: Colors.white.withValues(alpha: 0.2)),
                    const SizedBox(height: 16),
                    Text(
                      context.l10n.noHistory,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.l10n.noHistoryHint,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.25),
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: settings.presentationHistory.length,
              itemBuilder: (context, index) {
                final analytics = settings.presentationHistory[index];
                return _buildHistoryTile(context, analytics, settings);
              },
            ),
    );
  }

  Widget _buildHistoryTile(BuildContext context, PresentationAnalytics analytics, SettingsProvider settings) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Dismissible(
        key: Key(analytics.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: AppColors.danger.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.delete_rounded, color: AppColors.danger),
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
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
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
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.analyticsIndigo.withValues(alpha: 0.3),
                          AppColors.analyticsTeal.withValues(alpha: 0.15),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.slideshow_rounded, color: AppColors.analyticsIndigo, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          Formatters.formatDate(analytics.startTime, context.l10n),
                          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.timer_outlined, size: 14, color: Colors.white.withValues(alpha: 0.4)),
                            const SizedBox(width: 4),
                            Text(
                              Formatters.formatDuration(analytics.totalDuration, context.l10n),
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13),
                            ),
                            const SizedBox(width: 16),
                            Icon(Icons.layers_outlined, size: 14, color: Colors.white.withValues(alpha: 0.4)),
                            const SizedBox(width: 4),
                            Text(
                              context.l10n.slideCount(analytics.distinctSlideCount),
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: Colors.white.withValues(alpha: 0.3)),
                ],
              ),
            ),
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
