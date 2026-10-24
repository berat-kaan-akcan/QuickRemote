import 'package:flutter/material.dart';

import '../../theme/app_palette.dart';
import '../../theme/app_tokens.dart';
import '../../theme/app_typography.dart';
import 'pressable.dart';

/// One choice of an [AppSegmented].
class AppSegment<T> {
  const AppSegment({required this.value, required this.label, this.icon});

  final T value;
  final String label;
  final IconData? icon;
}

/// A segmented control whose selection slides between equal-width segments.
class AppSegmented<T> extends StatelessWidget {
  const AppSegmented({
    super.key,
    required this.segments,
    required this.selected,
    required this.onChanged,
    this.height = 44,
    this.color,
  });

  final List<AppSegment<T>> segments;
  final T selected;
  final ValueChanged<T> onChanged;
  final double height;

  /// Color of the selected segment; the primary color by default.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final accent = color ?? p.primary;
    final index = segments.indexWhere((s) => s.value == selected).clamp(0, segments.length - 1);
    final duration = AppMotion.of(context, AppMotion.base);
    final onAccent = readableOn(accent);

    return Container(
      height: height,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: p.surfaceSunken,
        borderRadius: AppRadius.all(AppRadius.sm + 2),
        border: Border.all(color: p.border),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: duration,
            curve: AppMotion.standard,
            alignment: segments.length == 1
                ? Alignment.center
                : Alignment(-1 + 2 * index / (segments.length - 1), 0),
            child: FractionallySizedBox(
              widthFactor: 1 / segments.length,
              heightFactor: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: AppRadius.all(AppRadius.sm - 1),
                  boxShadow: AppShadows.glow(accent, strength: 0.35),
                ),
              ),
            ),
          ),
          Row(
            children: [
              for (final segment in segments)
                Expanded(
                  child: Pressable(
                    onTap: () {
                      if (segment.value != selected) onChanged(segment.value);
                    },
                    selected: segment.value == selected,
                    pressedScale: 0.97,
                    borderRadius: AppRadius.all(AppRadius.sm),
                    child: Center(
                      child: AnimatedDefaultTextStyle(
                        duration: duration,
                        style: AppType.labelSmall.copyWith(
                          color: segment.value == selected ? onAccent : p.textSecondary,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (segment.icon != null) ...[
                              Icon(
                                segment.icon,
                                size: 16,
                                color: segment.value == selected ? onAccent : p.textSecondary,
                              ),
                              const SizedBox(width: 6),
                            ],
                            Flexible(
                              child: Text(segment.label, maxLines: 1, overflow: TextOverflow.ellipsis),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
