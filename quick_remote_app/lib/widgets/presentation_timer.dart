import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:vibration/vibration.dart';
import '../providers/settings_provider.dart';
import '../services/presentation_timer_controller.dart';
import '../utils/ui/app_bottom_sheet.dart';
import '../utils/ui/app_snackbar.dart';
import '../l10n/app_language.dart';
import 'duration_picker.dart';
import 'ui/ui.dart';

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
        final p = context.palette;
        final isOvertime = controller.isOvertime;
        var timeStr = formatTimerSeconds(controller.displaySeconds);
        if (isOvertime) timeStr = '+$timeStr';

        final color = isOvertime
            ? p.danger
            : controller.isRunning
                ? p.primaryText
                : p.textSecondary;
        final canReset = controller.isRunning || controller.elapsedSeconds > 0;
        final target = controller.targetSeconds;
        final progress = isOvertime
            ? 1.0
            : target > 0
                ? (controller.elapsedSeconds / target).clamp(0.0, 1.0)
                : 0.0;
        final ring = iconSize + 12;

        return Pressable(
          onTap: () => _toggle(context),
          onLongPress: () => showDurationPicker(context),
          semanticLabel: timeStr,
          borderRadius: AppRadius.all(AppRadius.pill),
          child: AnimatedContainer(
            duration: AppMotion.of(context, AppMotion.base),
            padding: EdgeInsets.fromLTRB(5, 5, canReset ? 5 : AppSpace.md, 5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: p.isDark ? 0.13 : 0.09),
              borderRadius: AppRadius.all(AppRadius.pill),
              border: Border.all(color: color.withValues(alpha: isOvertime ? 0.5 : 0.28)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox.square(
                  dimension: ring,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      TweenAnimationBuilder<double>(
                        tween: Tween(end: progress),
                        duration: AppMotion.of(context, AppMotion.slow),
                        builder: (context, value, _) => CircularProgressIndicator(
                          value: value,
                          strokeWidth: 2.5,
                          strokeCap: StrokeCap.round,
                          color: color,
                          backgroundColor: color.withValues(alpha: 0.16),
                        ),
                      ),
                      Icon(
                        controller.isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        color: color,
                        size: iconSize,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpace.xs),
                Text(
                  timeStr,
                  style: AppType.numeric.copyWith(
                    color: isOvertime ? p.danger : p.textPrimary,
                    fontSize: fontSize + 1,
                    letterSpacing: 0,
                  ),
                ),
                if (canReset) ...[
                  const SizedBox(width: AppSpace.xs),
                  Pressable(
                    onTap: _reset,
                    pressedScale: 0.85,
                    semanticLabel: MaterialLocalizations.of(context).refreshIndicatorSemanticLabel,
                    borderRadius: AppRadius.all(AppRadius.pill),
                    child: Container(
                      width: ring,
                      height: ring,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.14),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.refresh_rounded,
                        color: color,
                        size: iconSize * 0.85,
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
