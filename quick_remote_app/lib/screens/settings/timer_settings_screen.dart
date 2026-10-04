import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import '../../l10n/app_language.dart';
import '../../widgets/ui/ui.dart';
import 'widgets/add_warning_time_sheet.dart';
import 'widgets/vibration_pattern_sheet.dart';

class TimerSettingsScreen extends StatelessWidget {
  const TimerSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final p = context.palette;
    final sectionStyle = AppType.overline.copyWith(color: p.textSecondary);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.timerSettingsTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ContentWidth(
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            AppSpace.page,
            AppSpace.sm,
            AppSpace.page,
            MediaQuery.paddingOf(context).bottom + AppSpace.xl,
          ),
          children: [
            FadeSlideIn(
              child: AppSwitchTile(
                icon: Icons.play_circle_outline_rounded,
                title: context.l10n.timerAutoStartTitle,
                subtitle: context.l10n.timerAutoStartSubtitle,
                value: settings.timerAutoStart,
                onChanged: (val) => context.read<SettingsProvider>().setTimerAutoStart(val),
              ),
            ),
            const SizedBox(height: AppSpace.md),
            FadeSlideIn(
              index: 1,
              child: _SettingsCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppSwitchTile(
                      flat: true,
                      icon: Icons.notifications_active_outlined,
                      iconColor: p.warning,
                      title: context.l10n.earlyWarningTitle,
                      subtitle: context.l10n.earlyWarningSubtitle,
                      value: settings.earlyWarningHaptic,
                      onChanged: (val) => context.read<SettingsProvider>().setEarlyWarningHaptic(val),
                    ),
                    Reveal(
                      child: !settings.earlyWarningHaptic
                          ? null
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Divider(color: p.border, height: AppSpace.xl),
                                Text(context.l10n.warningTimes, style: sectionStyle),
                                const SizedBox(height: AppSpace.sm),
                                if (settings.warningTimes.isEmpty)
                                  Text(
                                    context.l10n.noWarningTimes,
                                    style: AppType.bodySmall.copyWith(color: p.textMuted),
                                  ),
                                for (final (index, seconds) in settings.warningTimes.indexed) ...[
                                  if (index > 0) const SizedBox(height: AppSpace.xs),
                                  _WarningTimeTile(
                                    seconds: seconds,
                                    pattern: settings.warningVibrations[seconds] ?? 'double',
                                  ),
                                ],
                                const SizedBox(height: AppSpace.sm),
                                AppButton(
                                  label: context.l10n.addWarning,
                                  icon: Icons.add_rounded,
                                  variant: AppButtonVariant.tonal,
                                  height: 48,
                                  onPressed: () => showAddWarningTimeSheet(context),
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpace.md),
            FadeSlideIn(
              index: 2,
              child: _SettingsCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.l10n.whenTimeIsUp, style: sectionStyle),
                    AppSwitchTile(
                      flat: true,
                      icon: Icons.vibration_rounded,
                      iconColor: p.danger,
                      title: context.l10n.endVibration,
                      value: settings.timeOutVibrationEnabled,
                      onChanged: (val) => context.read<SettingsProvider>().setTimeOutVibrationEnabled(val),
                    ),
                    Reveal(
                      child: !settings.timeOutVibrationEnabled
                          ? null
                          : Column(
                              children: [
                                Divider(color: p.border, height: AppSpace.md),
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: AppSpace.xs),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          context.l10n.vibrationPattern,
                                          style: AppType.body.copyWith(color: p.textSecondary, fontSize: 14),
                                        ),
                                      ),
                                      PatternChip(
                                        pattern: settings.timeOutVibrationPattern,
                                        showArrow: true,
                                        onTap: () => showVibrationPatternSheet(context, null, settings.timeOutVibrationPattern),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Material, not a colored box: the switch tiles draw their ink on it.
    final p = context.palette;
    return Material(
      color: p.surface,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.all(AppRadius.lg),
        side: BorderSide(color: p.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpace.md, AppSpace.sm, AppSpace.sm, AppSpace.md),
        child: child,
      ),
    );
  }
}

/// One early warning: when it fires, its vibration and a remove button.
class _WarningTimeTile extends StatelessWidget {
  const _WarningTimeTile({required this.seconds, required this.pattern});

  final int seconds;
  final String pattern;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpace.sm, AppSpace.xs, AppSpace.xxs, AppSpace.xs),
      decoration: BoxDecoration(
        color: p.surfaceSunken,
        borderRadius: AppRadius.all(AppRadius.md),
        border: Border.all(color: p.border),
      ),
      child: Row(
        children: [
          Icon(Icons.timer_outlined, color: p.warning, size: 20),
          const SizedBox(width: AppSpace.sm - 2),
          Expanded(
            child: Text(
              context.l10n.timeLeft(formatWarningTime(context, seconds)),
              style: AppType.titleSmall.copyWith(color: p.textPrimary, fontSize: 14),
            ),
          ),
          PatternChip(
            pattern: pattern,
            onTap: () => showVibrationPatternSheet(context, seconds, pattern),
          ),
          AppIconButton(
            icon: Icons.close_rounded,
            tooltip: MaterialLocalizations.of(context).deleteButtonTooltip,
            color: p.danger,
            size: 40,
            iconSize: 18,
            onPressed: () => context.read<SettingsProvider>().removeWarningTime(seconds),
          ),
        ],
      ),
    );
  }
}
