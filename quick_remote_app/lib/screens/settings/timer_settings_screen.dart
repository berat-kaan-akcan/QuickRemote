import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import '../../l10n/app_language.dart';
import '../../utils/ui/app_top_bar.dart';
import '../../widgets/ui/ui.dart';
import 'widgets/add_warning_time_sheet.dart';
import 'widgets/settings_rows.dart';
import 'widgets/vibration_pattern_sheet.dart';

class TimerSettingsScreen extends StatelessWidget {
  const TimerSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final p = context.palette;

    return Scaffold(
      appBar: AppTopBar(title: context.l10n.timerSettingsTitle),
      body: ContentWidth(
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            AppSpace.page,
            0,
            AppSpace.page,
            MediaQuery.paddingOf(context).bottom + AppSpace.xl,
          ),
          children: [
            FadeSlideIn(
              child: SettingsGroup(
                children: [
                  SettingsRow(
                    icon: Icons.play_circle_outline_rounded,
                    title: context.l10n.timerAutoStartTitle,
                    subtitle: context.l10n.timerAutoStartSubtitle,
                    alignTop: true,
                    value: settings.timerAutoStart,
                    onChanged: settings.setTimerAutoStart,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpace.sm),
            FadeSlideIn(
              index: 1,
              child: SettingsGroup(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SettingsRow(
                        icon: Icons.notifications_active_outlined,
                        iconColor: p.warning,
                        title: context.l10n.earlyWarningTitle,
                        subtitle: context.l10n.earlyWarningSubtitle,
                        alignTop: true,
                        value: settings.earlyWarningHaptic,
                        onChanged: settings.setEarlyWarningHaptic,
                      ),
                      Reveal(
                        child: !settings.earlyWarningHaptic
                            ? null
                            : Padding(
                                padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      context.l10n.warningTimes.toUpperCase(),
                                      style: AppType.overline.copyWith(color: p.textMuted),
                                    ),
                                    const SizedBox(height: AppSpace.xs),
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
                                      height: 46,
                                      onPressed: () => showAddWarningTimeSheet(context),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpace.sm),
            FadeSlideIn(index: 2, child: SettingsSectionLabel(context.l10n.whenTimeIsUp)),
            FadeSlideIn(
              index: 3,
              child: SettingsGroup(
                children: [
                  SettingsRow(
                    icon: Icons.vibration_rounded,
                    iconColor: p.danger,
                    title: context.l10n.endVibration,
                    value: settings.timeOutVibrationEnabled,
                    onChanged: settings.setTimeOutVibrationEnabled,
                  ),
                  if (settings.timeOutVibrationEnabled)
                    SettingsRow(
                      inset: true,
                      title: context.l10n.vibrationPattern,
                      subtitle: vibrationPatternName(context, settings.timeOutVibrationPattern),
                      onTap: () => showVibrationPatternSheet(context, null, settings.timeOutVibrationPattern),
                    ),
                ],
              ),
            ),
          ],
        ),
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
      padding: const EdgeInsets.fromLTRB(AppSpace.sm, 6, AppSpace.xxs, 6),
      decoration: BoxDecoration(
        color: p.surfaceSunken,
        borderRadius: AppRadius.all(AppRadius.sm),
      ),
      child: Row(
        children: [
          Icon(Icons.timer_outlined, color: p.warning, size: 20),
          const SizedBox(width: 10),
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
            color: p.textMuted,
            size: 40,
            iconSize: 18,
            onPressed: () => context.read<SettingsProvider>().removeWarningTime(seconds),
          ),
        ],
      ),
    );
  }
}
