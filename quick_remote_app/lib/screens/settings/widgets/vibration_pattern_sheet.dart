import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../providers/settings_provider.dart';
import '../../../utils/ui/app_bottom_sheet.dart';
import '../../../widgets/presentation_timer.dart';
import '../../../l10n/app_language.dart';
import '../../../widgets/ui/ui.dart';
import 'settings_rows.dart';


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
      final p = ctx.palette;
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppBottomSheet.buildHeader(
            timeInSeconds != null
                ? context.l10n.vibrationFor(formatWarningTime(context, timeInSeconds))
                : context.l10n.endVibration,
            icon: Icons.vibration_rounded,
            iconColor: p.danger,
          ),
          const SizedBox(height: AppSpace.xxs),
          Text(context.l10n.tapToPreview, style: AppType.bodySmall.copyWith(color: p.textSecondary)),
          const SizedBox(height: AppSpace.sm),
          for (final (value, label) in [
            ('short', context.l10n.vibrationShort),
            ('double', context.l10n.vibrationDouble),
            ('long', context.l10n.vibrationLong),
            ('triple', context.l10n.vibrationTriple),
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpace.xs),
              child: RadioRow(
                label: label,
                selected: currentPattern == value,
                leading: _PatternGlyph(pattern: value),
                onTap: () {
                  HapticFeedback.mediumImpact();
                  vibrateTimerPattern(value);
                  if (timeInSeconds != null) {
                    ctx.read<SettingsProvider>().updateWarningPattern(timeInSeconds, value);
                  } else {
                    ctx.read<SettingsProvider>().setTimeOutVibrationPattern(value);
                  }
                  Future.delayed(const Duration(milliseconds: 400), () {
                    if (!ctx.mounted) return;
                    if (Navigator.canPop(ctx)) Navigator.pop(ctx);
                  });
                },
              ),
            ),
          const SizedBox(height: AppSpace.xs),
          AppBottomSheet.buildCancelButton(ctx),
        ],
      );
    },
  );
}

/// The pattern drawn as its pulses: one short, two, one long, three.
class _PatternGlyph extends StatelessWidget {
  const _PatternGlyph({required this.pattern});

  final String pattern;

  @override
  Widget build(BuildContext context) {
    final color = context.palette.primaryText;
    final widths = switch (pattern) {
      'short' => const [10.0],
      'long' => const [36.0],
      'triple' => const [10.0, 10.0, 10.0],
      _ => const [10.0, 10.0],
    };
    return SizedBox(
      width: 40,
      child: Row(
        children: [
          for (final (i, w) in widths.indexed) ...[
            if (i > 0) const SizedBox(width: 3),
            Container(
              width: w,
              height: 14,
              decoration: BoxDecoration(color: color, borderRadius: AppRadius.all(3)),
            ),
          ],
        ],
      ),
    );
  }
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
