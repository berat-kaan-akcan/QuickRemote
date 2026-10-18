import 'package:flutter/material.dart';
import '../../../models/presentation_analytics.dart';
import '../../../utils/formatters.dart';
import '../../../l10n/app_language.dart';
import '../../../widgets/ui/ui.dart';

class SlideDurationList extends StatelessWidget {
  final PresentationAnalytics analytics;

  const SlideDurationList({super.key, required this.analytics});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final tps = analytics.timePerSlide;
    final sortedSlides = tps.keys.toList()..sort();

    if (sortedSlides.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.xxl),
          child: EmptyState(
            compact: true,
            icon: Icons.bar_chart_rounded,
            tone: AppTone.neutral,
            title: context.l10n.noSlideData,
          ),
        ),
      );
    }

    final maxDuration = tps.values.isEmpty
        ? const Duration(seconds: 1)
        : tps.values.reduce((a, b) => a > b ? a : b);

    final longest = analytics.longestSlide;

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.page),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: AppSpace.sm),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: AppRadius.all(AppRadius.md),
            border: Border.all(color: p.border),
          ),
          child: Column(
            children: [
              for (final (index, slideNum) in sortedSlides.indexed)
                Builder(
                  builder: (context) {
                    final duration = tps[slideNum]!;
                    final ratio = maxDuration.inMilliseconds > 0
                        ? duration.inMilliseconds / maxDuration.inMilliseconds
                        : 0.0;
                    final isLongest = longest != null && slideNum == longest.key;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: _SlideBar(
                        index: index,
                        label: context.l10n.reportSlide(slideNum),
                        value: Formatters.formatDurationShort(duration),
                        ratio: ratio.clamp(0.03, 1.0),
                        color: isLongest ? p.accent : p.primaryText,
                        semanticLabel:
                            '${context.l10n.reportSlide(slideNum)}: ${Formatters.formatDuration(duration, context.l10n)}',
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One slide's bar; it grows to its length when it first appears.
class _SlideBar extends StatelessWidget {
  const _SlideBar({
    required this.index,
    required this.label,
    required this.value,
    required this.ratio,
    required this.color,
    required this.semanticLabel,
  });

  final int index;
  final String label;
  final String value;
  final double ratio;
  final Color color;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = AppType.bodySmall.copyWith(color: p.textPrimary, fontSize: 12.5, fontWeight: FontWeight.w500);
    return Semantics(
      label: semanticLabel,
      child: ExcludeSemantics(
        child: Row(
          children: [
            SizedBox(width: 64, child: Text(label, maxLines: 1, style: text)),
            Expanded(
              child: ClipRRect(
                borderRadius: AppRadius.all(5),
                child: SizedBox(
                  height: 10,
                  child: Stack(
                    children: [
                      Positioned.fill(child: ColoredBox(color: p.surfaceSunken)),
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: AppMotion.reduced(context) ? ratio : 0, end: ratio),
                        duration: AppMotion.of(context, AppMotion.slow + AppMotion.stagger * index.clamp(0, 10)),
                        curve: AppMotion.standard,
                        builder: (context, t, _) => FractionallySizedBox(
                          widthFactor: t,
                          heightFactor: 1,
                          child: DecoratedBox(
                            decoration: BoxDecoration(color: color, borderRadius: AppRadius.all(5)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(
              width: 44,
              child: Text(value, textAlign: TextAlign.right, style: text.copyWith(color: p.textSecondary)),
            ),
          ],
        ),
      ),
    );
  }
}
