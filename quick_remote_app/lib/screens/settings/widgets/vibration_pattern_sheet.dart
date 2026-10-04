import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../providers/settings_provider.dart';
import '../../../utils/ui/app_bottom_sheet.dart';
import '../../../widgets/presentation_timer.dart';
import '../../../l10n/app_language.dart';
import '../../../widgets/ui/ui.dart';


String formatWarningTime(BuildContext context, int seconds) {
  if (seconds >= 60) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    if (s == 0) return context.l10n.durationMinutes(m);
    return context.l10n.durationMinSec(m, s);
  }
  return context.l10n.durationSeconds(seconds);
}

String vibrationPatternName(BuildContext context, String pattern) {
  switch (pattern) {
    case 'short': return context.l10n.patternShort;
    case 'long': return context.l10n.patternLong;
    case 'triple': return context.l10n.patternTriple;
    case 'double':
    default: return context.l10n.patternDouble;
  }
}

/// Picks the vibration for a warning time, or for the end when
/// [timeInSeconds] is null. Each choice is played as a preview.
void showVibrationPatternSheet(BuildContext context, int? timeInSeconds, String currentPattern) {
  AppBottomSheet.show(
    context: context,
    builder: (ctx) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppBottomSheet.buildTitle(
            timeInSeconds != null 
              ? context.l10n.vibrationFor(formatWarningTime(context, timeInSeconds))
              : context.l10n.endVibration,
            icon: Icons.vibration_rounded,
          ),
          const SizedBox(height: AppSpace.xs),
          Text(
            context.l10n.tapToPreview,
            style: AppType.bodySmall.copyWith(color: ctx.palette.textMuted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpace.lg),
          _option(ctx, timeInSeconds, currentPattern, 'short', context.l10n.vibrationShort, Icons.short_text_rounded),
          _option(ctx, timeInSeconds, currentPattern, 'double', context.l10n.vibrationDouble, Icons.view_stream_rounded),
          _option(ctx, timeInSeconds, currentPattern, 'long', context.l10n.vibrationLong, Icons.horizontal_rule_rounded),
          _option(ctx, timeInSeconds, currentPattern, 'triple', context.l10n.vibrationTriple, Icons.dehaze_rounded),
          const SizedBox(height: AppSpace.md),
          AppBottomSheet.buildCancelButton(ctx),
        ],
      );
    },
  );
}

Widget _option(BuildContext context, int? timeInSeconds, String currentPattern, String value, String label, IconData icon) {
  final isSelected = currentPattern == value;
  final p = context.palette;
  final primaryColor = p.primaryText;

  return Padding(
    padding: const EdgeInsets.only(bottom: AppSpace.xs),
    child: Pressable(
      selected: isSelected,
      pressedScale: 0.98,
      borderRadius: AppRadius.all(AppRadius.md),
      onTap: () {
        HapticFeedback.mediumImpact();
        vibrateTimerPattern(value);
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
      child: AnimatedContainer(
        duration: AppMotion.of(context, AppMotion.base),
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.md),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor.withValues(alpha: p.isDark ? 0.14 : 0.08) : p.surfaceSunken,
          borderRadius: AppRadius.all(AppRadius.md),
          border: Border.all(color: isSelected ? primaryColor.withValues(alpha: 0.5) : p.border),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? primaryColor : p.textSecondary, size: 22),
            const SizedBox(width: AppSpace.md),
            Expanded(
              child: Text(
                label,
                style: AppType.titleSmall.copyWith(
                  color: isSelected ? primaryColor : p.textPrimary,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded, color: primaryColor, size: 22),
          ],
        ),
      ),
    ),
  );
}

/// The current vibration pattern; tapping it opens the picker.
class PatternChip extends StatelessWidget {
  const PatternChip({super.key, required this.pattern, required this.onTap, this.showArrow = false});

  final String pattern;
  final VoidCallback onTap;
  final bool showArrow;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final primary = p.primaryText;
    return Pressable(
      onTap: onTap,
      pressedScale: 0.94,
      borderRadius: AppRadius.all(AppRadius.pill),
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm),
        decoration: BoxDecoration(
          color: primary.withValues(alpha: p.isDark ? 0.14 : 0.09),
          borderRadius: AppRadius.all(AppRadius.pill),
          border: Border.all(color: primary.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.vibration_rounded, size: 15, color: primary),
            const SizedBox(width: 6),
            Text(
              vibrationPatternName(context, pattern),
              style: AppType.labelSmall.copyWith(color: primary),
            ),
            if (showArrow) ...[
              const SizedBox(width: 2),
              Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: primary),
            ],
          ],
        ),
      ),
    );
  }
}
