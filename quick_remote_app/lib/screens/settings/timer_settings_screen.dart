import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import '../../l10n/app_language.dart';
import '../../theme/app_colors.dart';
import 'widgets/add_warning_time_sheet.dart';
import 'widgets/vibration_pattern_sheet.dart';

class TimerSettingsScreen extends StatelessWidget {
  const TimerSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final primary = Theme.of(context).colorScheme.primary;
    const titleStyle = TextStyle(color: Colors.white, fontWeight: FontWeight.w500);
    final subtitleStyle = TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12);
    const sectionStyle = TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          context.l10n.timerSettingsTitle,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _SettingsCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(context.l10n.timerAutoStartTitle, style: titleStyle),
              subtitle: Text(context.l10n.timerAutoStartSubtitle, style: subtitleStyle),
              value: settings.timerAutoStart,
              activeThumbColor: primary,
              onChanged: (val) => context.read<SettingsProvider>().setTimerAutoStart(val),
            ),
          ),
          const SizedBox(height: 16),
          _SettingsCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(context.l10n.earlyWarningTitle, style: titleStyle),
                  subtitle: Text(context.l10n.earlyWarningSubtitle, style: subtitleStyle),
                  value: settings.earlyWarningHaptic,
                  activeThumbColor: primary,
                  onChanged: (val) => context.read<SettingsProvider>().setEarlyWarningHaptic(val),
                ),
                if (settings.earlyWarningHaptic) ...[
                  const Divider(color: Colors.white12, height: 32),
                  Text(context.l10n.warningTimes, style: sectionStyle),
                  const SizedBox(height: 12),
                  if (settings.warningTimes.isEmpty)
                    Text(
                      context.l10n.noWarningTimes,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13),
                    ),
                  for (final (index, seconds) in settings.warningTimes.indexed) ...[
                    if (index > 0) const SizedBox(height: 8),
                    _WarningTimeTile(
                      seconds: seconds,
                      pattern: settings.warningVibrations[seconds] ?? 'double',
                    ),
                  ],
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => showAddWarningTimeSheet(context),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: Text(context.l10n.addWarning),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primary,
                        side: BorderSide(color: primary.withValues(alpha: 0.5)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SettingsCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.l10n.whenTimeIsUp, style: sectionStyle),
                const SizedBox(height: 12),
                Material(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      SwitchListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                        title: Text(
                          context.l10n.endVibration,
                          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        value: settings.timeOutVibrationEnabled,
                        activeThumbColor: primary,
                        onChanged: (val) => context.read<SettingsProvider>().setTimeOutVibrationEnabled(val),
                      ),
                      if (settings.timeOutVibrationEnabled) ...[
                        const Divider(color: Colors.white12, height: 1, indent: 16, endIndent: 16),
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                          title: Text(
                            context.l10n.vibrationPattern,
                            style: const TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                          trailing: PatternChip(
                            pattern: settings.timeOutVibrationPattern,
                            showArrow: true,
                            onTap: () => showVibrationPatternSheet(context, null, settings.timeOutVibrationPattern),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.child, this.padding = const EdgeInsets.all(16)});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    // Material, not a colored box: the switch tiles draw their ink on it.
    return Material(
      color: Colors.white.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: Padding(padding: padding, child: child),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.timer_outlined, color: Colors.white70, size: 20),
          const SizedBox(width: 12),
          Text(
            context.l10n.timeLeft(formatWarningTime(context, seconds)),
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          PatternChip(
            pattern: pattern,
            onTap: () => showVibrationPatternSheet(context, seconds, pattern),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => context.read<SettingsProvider>().removeWarningTime(seconds),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close_rounded, color: Colors.redAccent, size: 16),
            ),
          ),
        ],
      ),
    );
  }
}
