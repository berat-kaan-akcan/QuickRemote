import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:vibration/vibration.dart';
import '../providers/settings_provider.dart';
import '../services/presentation_timer_controller.dart';
import '../utils/ui/app_bottom_sheet.dart';
import '../utils/ui/app_snackbar.dart';
import '../l10n/app_language.dart';
import '../theme/app_colors.dart';
import 'duration_picker.dart';

/// Vibrates with one of the patterns chosen in the timer settings.
void vibrateTimerPattern(String pattern) {
  switch (pattern) {
    case 'short':
      Vibration.vibrate(pattern: [0, 300]);
      break;
    case 'long':
      Vibration.vibrate(pattern: [0, 800]);
      break;
    case 'triple':
      Vibration.vibrate(pattern: [0, 500, 150, 500, 150, 800]);
      break;
    case 'double':
    default:
      Vibration.vibrate(pattern: [0, 300, 100, 300]);
      break;
  }
}

String formatTimerSeconds(int seconds) {
  final int m = seconds ~/ 60;
  final int s = seconds % 60;
  return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
}

/// Connects [controller] to the timer settings: early warnings, vibration
/// patterns and the snackbars shown on [context].
void bindTimerToSettings(BuildContext context, PresentationTimerController controller) {
  final settings = context.read<SettingsProvider>();
  controller.warningTimes = () => settings.earlyWarningHaptic ? settings.warningTimes : const [];
  controller.onAlert = (alert) {
    if (!context.mounted) return;
    if (alert.kind == TimerAlertKind.timeUp) {
      if (settings.timeOutVibrationEnabled) vibrateTimerPattern(settings.timeOutVibrationPattern);
      AppSnackbar.show(
        context,
        message: context.l10n.timeUp,
        type: SnackbarType.error,
        duration: const Duration(seconds: 3),
      );
    } else {
      vibrateTimerPattern(settings.warningVibrations[alert.remainingSeconds] ?? 'double');
      AppSnackbar.show(
        context,
        message: context.l10n.timeRemaining(formatTimerSeconds(alert.remainingSeconds)),
        type: SnackbarType.warning,
        duration: const Duration(seconds: 2),
      );
    }
  };
}

class PresentationTimer extends StatelessWidget {
  final PresentationTimerController controller;
  final double fontSize;
  final double iconSize;

  const PresentationTimer({
    super.key,
    required this.controller,
    this.fontSize = 16.0,
    this.iconSize = 18.0,
  });

  void _toggle(BuildContext context) {
    if (controller.isRunning) {
      HapticFeedback.lightImpact();
      controller.pause();
    } else if (!controller.isDurationSelected) {
      showDurationPicker(context);
    } else {
      HapticFeedback.lightImpact();
      controller.start();
    }
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    controller.reset();
  }

  void showDurationPicker(BuildContext context) {
    HapticFeedback.mediumImpact();
    AppBottomSheet.show(
      context: context,
      builder: (ctx) => DurationPicker(
        initialSeconds: controller.isDurationSelected ? controller.targetSeconds : null,
        onSelected: (seconds, start) {
          Navigator.of(ctx).pop();
          if (start) HapticFeedback.lightImpact();
          controller.setDuration(seconds, start: start);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final isOvertime = controller.isOvertime;
        var timeStr = formatTimerSeconds(controller.displaySeconds);
        if (isOvertime) timeStr = '+$timeStr';

        final primary = Theme.of(context).colorScheme.primary;
        final textColor = isOvertime ? AppColors.danger : Colors.white;
        final bgColor = isOvertime
            ? AppColors.danger.withValues(alpha: 0.15)
            : primary.withValues(alpha: 0.15);
        final borderColor = isOvertime
            ? AppColors.danger.withValues(alpha: 0.5)
            : primary.withValues(alpha: 0.3);
        final canReset = controller.isRunning || controller.elapsedSeconds > 0;

        return GestureDetector(
          onTap: () => _toggle(context),
          onLongPress: () => showDurationPicker(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  controller.isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: textColor,
                  size: iconSize,
                ),
                const SizedBox(width: 8),
                Text(
                  timeStr,
                  style: TextStyle(
                    color: textColor,
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                if (canReset) ...[
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _reset,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: textColor.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.refresh_rounded,
                        color: textColor,
                        size: iconSize * 0.8,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
