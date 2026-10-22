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
void bindTimerToSettings(
  BuildContext context,
  PresentationTimerController controller,
) {
  final settings = context.read<SettingsProvider>();
  controller.warningTimes = () =>
      settings.earlyWarningHaptic ? settings.warningTimes : const [];
  controller.onAlert = (alert) {
    if (!context.mounted) return;
    if (alert.kind == TimerAlertKind.timeUp) {
      if (settings.timeOutVibrationEnabled) {
        vibrateTimerPattern(settings.timeOutVibrationPattern);
      }
      AppSnackbar.show(
        context,
        message: context.l10n.timeUp,
        type: SnackbarType.error,
        duration: const Duration(seconds: 3),
      );
    } else {
      vibrateTimerPattern(
        settings.warningVibrations[alert.remainingSeconds] ?? 'double',
      );
      AppSnackbar.show(
        context,
        message: context.l10n.timeRemaining(
          formatTimerSeconds(alert.remainingSeconds),
        ),
        type: SnackbarType.warning,
        duration: const Duration(seconds: 2),
      );
    }
  };
}

/// The talk's clock: the time, a play/pause and a reset key. A tap starts or
/// pauses it, a long press picks a new length. [tall] sits beside the
/// Start/End button above the touchpad.
class PresentationTimer extends StatelessWidget {
  final PresentationTimerController controller;
  final bool tall;

  const PresentationTimer({
    super.key,
    required this.controller,
    this.tall = false,
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
        initialSeconds: controller.isDurationSelected
            ? controller.targetSeconds
            : null,
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

        final iconColor = isOvertime
            ? p.danger
            : controller.isRunning
            ? p.warning
            : p.textMuted;
        // Large text leaves no room for the key that only mirrors the chip.
        final compact = MediaQuery.textScalerOf(context).scale(16) > 18.4;
        final canReset = controller.isRunning || controller.elapsedSeconds > 0;

        // The digits are a few characters in a chip beside other keys: they
        // grow with the system's text size, but stop at 1.3 so the chip never
        // pushes its neighbours off the screen.
        return MediaQuery.withClampedTextScaling(
          maxScaleFactor: 1.3,
          child: Pressable(
            // The reset key inside is a button of its own.
            keepChildSemantics: true,
            onTap: () => _toggle(context),
            onLongPress: () => showDurationPicker(context),
            semanticLabel: controller.isRunning
                ? context.l10n.timerPauseLabel(timeStr)
                : context.l10n.timerStartLabel(timeStr),
            borderRadius: AppRadius.all(AppRadius.sm),
            child: AnimatedContainer(
              duration: AppMotion.of(context, AppMotion.base),
              height: tall ? 50 : null,
              padding: const EdgeInsets.fromLTRB(10, 0, 6, 0),
              decoration: BoxDecoration(
                color: p.surfaceSunken,
                borderRadius: AppRadius.all(AppRadius.sm),
                border: Border.all(
                  color: isOvertime
                      ? p.danger.withValues(alpha: 0.5)
                      : p.border,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!compact) ...[
                    ExcludeSemantics(child: Icon(Icons.timer_outlined, color: iconColor, size: 18)),
                    const SizedBox(width: 6),
                  ],
                  ExcludeSemantics(child: Text(
                    timeStr,
                    style: AppType.numeric.copyWith(
                      color: isOvertime ? p.danger : p.textPrimary,
                      fontSize: 18,
                      letterSpacing: 0,
                    ),
                  )),
                  const SizedBox(width: 6),
                  if (!compact) ...[
                    // The chip itself starts and pauses; this only shows which.
                    ExcludeSemantics(
                      child: _TimerKey(
                        icon: controller.isRunning
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        semanticLabel: '',
                        onTap: () => _toggle(context),
                        touchTarget: false,
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  _TimerKey(
                    icon: Icons.refresh_rounded,
                    semanticLabel: context.l10n.timerResetLabel,
                    onTap: canReset ? _reset : null,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// A small square key inside the timer.
class _TimerKey extends StatelessWidget {
  const _TimerKey({
    required this.icon,
    required this.semanticLabel,
    this.onTap,
    this.touchTarget = true,
  });

  final IconData icon;
  final String semanticLabel;

  /// Gives the key the 48 px touch area; off for the one the chip duplicates.
  final bool touchTarget;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Pressable(
      onTap: onTap,
      pressedScale: 0.85,
      minTarget: touchTarget ? 48 : 0,
      semanticLabel: semanticLabel,
      borderRadius: AppRadius.all(AppRadius.xs),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: p.surfaceRaised,
          borderRadius: AppRadius.all(AppRadius.xs),
        ),
        child: Icon(icon, color: p.textSecondary, size: 18),
      ),
    );
  }
}
