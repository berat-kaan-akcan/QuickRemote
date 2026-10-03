import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import '../../utils/ui/app_bottom_sheet.dart';
import '../../utils/ui/app_popup_theme.dart';
import '../../utils/ui/app_snackbar.dart';
import '../../widgets/presentation_timer.dart';
import '../../l10n/app_language.dart';

class TimerSettingsScreen extends StatelessWidget {
  const TimerSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(context.l10n.timerSettingsTitle, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
            ),
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                context.l10n.timerAutoStartTitle,
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
              ),
              subtitle: Text(
                context.l10n.timerAutoStartSubtitle,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
              ),
              value: settings.timerAutoStart,
              activeThumbColor: Theme.of(context).colorScheme.primary,
              onChanged: (val) => context.read<SettingsProvider>().setTimerAutoStart(val),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    context.l10n.earlyWarningTitle,
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(
                    context.l10n.earlyWarningSubtitle,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
                  ),
                  value: settings.earlyWarningHaptic,
                  activeThumbColor: Theme.of(context).colorScheme.primary,
                  onChanged: (val) {
                    context.read<SettingsProvider>().setEarlyWarningHaptic(val);
                  },
                ),
                if (settings.earlyWarningHaptic) ...[
                  const Divider(color: Colors.white12, height: 32),
                  Text(
                    context.l10n.warningTimes,
                    style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 12),
                  if (settings.warningTimes.isEmpty)
                    Text(
                      context.l10n.noWarningTimes,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13),
                    ),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: settings.warningTimes.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final timeInSeconds = settings.warningTimes[index];
                      final pattern = settings.warningVibrations[timeInSeconds] ?? 'double';
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF262C4A),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.timer_outlined, color: Colors.white70, size: 20),
                            const SizedBox(width: 12),
                            Text(
                              context.l10n.timeLeft(_formatSecondsToText(context, timeInSeconds)),
                              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: () => _showPatternDialog(context, timeInSeconds, pattern),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.vibration_rounded, size: 14, color: Theme.of(context).colorScheme.primary),
                                    const SizedBox(width: 6),
                                    Text(
                                      _getPatternName(context, pattern),
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.primary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            GestureDetector(
                              onTap: () => context.read<SettingsProvider>().removeWarningTime(timeInSeconds),
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
                    },
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _showAddWarningTimeDialog(context),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: Text(context.l10n.addWarning),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.primary,
                        side: BorderSide(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)),
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
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.whenTimeIsUp,
                  style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF262C4A),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      SwitchListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                        title: Text(
                          context.l10n.endVibration,
                          style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        value: settings.timeOutVibrationEnabled,
                        activeThumbColor: Theme.of(context).colorScheme.primary,
                        onChanged: (val) {
                          context.read<SettingsProvider>().setTimeOutVibrationEnabled(val);
                        },
                      ),
                      if (settings.timeOutVibrationEnabled) ...[
                        const Divider(color: Colors.white12, height: 1, indent: 16, endIndent: 16),
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                          title: Text(context.l10n.vibrationPattern, style: TextStyle(color: Colors.white70, fontSize: 14)),
                          trailing: GestureDetector(
                            onTap: () => _showPatternDialog(context, null, settings.timeOutVibrationPattern),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.vibration_rounded, size: 14, color: Theme.of(context).colorScheme.primary),
                                  const SizedBox(width: 6),
                                  Text(
                                    _getPatternName(context, settings.timeOutVibrationPattern),
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.primary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Theme.of(context).colorScheme.primary),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ]
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

  String _formatSecondsToText(BuildContext context, int seconds) {
    if (seconds >= 60) {
      final m = seconds ~/ 60;
      final s = seconds % 60;
      if (s == 0) return context.l10n.durationMinutes(m);
      return context.l10n.durationMinSec(m, s);
    }
    return context.l10n.durationSeconds(seconds);
  }

  String _getPatternName(BuildContext context, String pattern) {
    switch (pattern) {
      case 'short': return context.l10n.patternShort;
      case 'long': return context.l10n.patternLong;
      case 'triple': return context.l10n.patternTriple;
      case 'double':
      default: return context.l10n.patternDouble;
    }
  }

  void _showPatternDialog(BuildContext context, int? timeInSeconds, String currentPattern) {
    AppBottomSheet.show(
      context: context,
      builder: (ctx) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBottomSheet.buildTitle(
              timeInSeconds != null 
                ? context.l10n.vibrationFor(_formatSecondsToText(context, timeInSeconds))
                : context.l10n.endVibration,
              icon: Icons.vibration_rounded,
            ),
            const SizedBox(height: 6),
            Text(
              context.l10n.tapToPreview,
              style: TextStyle(color: Colors.white54, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            _buildSheetOption(ctx, timeInSeconds, currentPattern, 'short', context.l10n.vibrationShort, Icons.short_text_rounded),
            _buildSheetOption(ctx, timeInSeconds, currentPattern, 'double', context.l10n.vibrationDouble, Icons.view_stream_rounded),
            _buildSheetOption(ctx, timeInSeconds, currentPattern, 'long', context.l10n.vibrationLong, Icons.horizontal_rule_rounded),
            _buildSheetOption(ctx, timeInSeconds, currentPattern, 'triple', context.l10n.vibrationTriple, Icons.dehaze_rounded),
            const SizedBox(height: 16),
            AppBottomSheet.buildCancelButton(ctx),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  Widget _buildSheetOption(BuildContext context, int? timeInSeconds, String currentPattern, String value, String label, IconData icon) {
    final isSelected = currentPattern == value;
    final primaryColor = Theme.of(context).colorScheme.primary;
    
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        HapticFeedback.mediumImpact();
        _previewVibration(value);
        if (timeInSeconds != null) {
          context.read<SettingsProvider>().updateWarningPattern(timeInSeconds, value);
        } else {
          context.read<SettingsProvider>().setTimeOutVibrationPattern(value);
        }
        Future.delayed(const Duration(milliseconds: 400), () {
          if (!context.mounted) return;
          if (Navigator.canPop(context)) Navigator.pop(context);
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? primaryColor : Colors.white54, size: 24),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? primaryColor : Colors.white,
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const Spacer(),
            if (isSelected)
              Icon(Icons.check_circle_rounded, color: primaryColor, size: 20),
          ],
        ),
      ),
    );
  }

  void _previewVibration(String pattern) => vibrateTimerPattern(pattern);

  void _showAddWarningTimeDialog(BuildContext context) {
    AppBottomSheet.show(
      context: context,
      builder: (ctx) {
        final controller = TextEditingController();
        bool isMinutes = false;

        return StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppBottomSheet.buildTitle(context.l10n.newWarningTime, icon: Icons.timer_rounded),
                const SizedBox(height: 24),
                TextField(
                  controller: controller,
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: AppPopupTheme.inputDecoration(
                    context: context,
                    hintText: context.l10n.enterTime,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _TypeChip(
                        label: context.l10n.unitSecondsLong,
                        isSelected: !isMinutes,
                        onTap: () => setState(() => isMinutes = false),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _TypeChip(
                        label: context.l10n.unitMinutesLong,
                        isSelected: isMinutes,
                        onTap: () => setState(() => isMinutes = true),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.white.withValues(alpha: 0.08),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            context.l10n.cancel,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: FilledButton(
                          onPressed: () {
                            final val = int.tryParse(controller.text);
                            if (val != null && val > 0) {
                              final seconds = isMinutes ? val * 60 : val;
                              context.read<SettingsProvider>().addWarningTime(seconds);
                              Navigator.of(ctx).pop();
                            } else {
                              AppSnackbar.show(
                                ctx,
                                message: context.l10n.enterValidNumber,
                                type: SnackbarType.error,
                              );
                            }
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppPopupTheme.buttonRadius),
                            ),
                          ),
                          child: Text(context.l10n.add, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            );
          },
        );
      },
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeChip({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected 
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.05),
          border: Border.all(
            color: isSelected 
                ? Theme.of(context).colorScheme.primary
                : Colors.transparent,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Theme.of(context).colorScheme.primary : Colors.white70,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
