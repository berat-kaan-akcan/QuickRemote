import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../providers/settings_provider.dart';
import '../../../utils/ui/app_bottom_sheet.dart';
import '../../../widgets/presentation_timer.dart';
import '../../../l10n/app_language.dart';


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
          const SizedBox(height: 6),
          Text(
            context.l10n.tapToPreview,
            style: TextStyle(color: Colors.white54, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          _option(ctx, timeInSeconds, currentPattern, 'short', context.l10n.vibrationShort, Icons.short_text_rounded),
          _option(ctx, timeInSeconds, currentPattern, 'double', context.l10n.vibrationDouble, Icons.view_stream_rounded),
          _option(ctx, timeInSeconds, currentPattern, 'long', context.l10n.vibrationLong, Icons.horizontal_rule_rounded),
          _option(ctx, timeInSeconds, currentPattern, 'triple', context.l10n.vibrationTriple, Icons.dehaze_rounded),
          const SizedBox(height: 16),
          AppBottomSheet.buildCancelButton(ctx),
          const SizedBox(height: 8),
        ],
      );
    },
  );
}

Widget _option(BuildContext context, int? timeInSeconds, String currentPattern, String value, String label, IconData icon) {
  final isSelected = currentPattern == value;
  final primaryColor = Theme.of(context).colorScheme.primary;
  
  return InkWell(
    borderRadius: BorderRadius.circular(12),
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

/// The current vibration pattern; tapping it opens the picker.
class PatternChip extends StatelessWidget {
  const PatternChip({super.key, required this.pattern, required this.onTap, this.showArrow = false});

  final String pattern;
  final VoidCallback onTap;
  final bool showArrow;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: primary.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.vibration_rounded, size: 14, color: primary),
            const SizedBox(width: 6),
            Text(
              vibrationPatternName(context, pattern),
              style: TextStyle(color: primary, fontSize: 12, fontWeight: FontWeight.bold),
            ),
            if (showArrow) ...[
              const SizedBox(width: 4),
              Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: primary),
            ],
          ],
        ),
      ),
    );
  }
}
