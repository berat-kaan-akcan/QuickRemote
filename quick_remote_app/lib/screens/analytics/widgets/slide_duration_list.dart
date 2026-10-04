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
    final shortest = analytics.shortestSlide;

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final slideNum = sortedSlides[index];
          final duration = tps[slideNum]!;
          final ratio = maxDuration.inMilliseconds > 0
              ? duration.inMilliseconds / maxDuration.inMilliseconds
              : 0.0;

          final isLongest = longest != null && slideNum == longest.key;
          final isShortest = shortest != null && slideNum == shortest.key && !isLongest;

          final Color barColor;
          if (isLongest) {
            barColor = p.accent;
          } else if (isShortest) {
            barColor = p.success;
          } else {
            barColor = p.primaryText;
          }

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.page, vertical: AppSpace.xxs),
            child: _SlideBar(
              index: index,
              label: 'S$slideNum',
              value: Formatters.formatDurationShort(duration),
              ratio: ratio.clamp(0.03, 1.0),
              color: barColor,
              semanticLabel: '${context.l10n.reportSlide(slideNum)}: ${Formatters.formatDuration(duration, context.l10n)}',
            ),
          );
        },
        childCount: sortedSlides.length,
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
    final valueStyle = AppType.mono.copyWith(fontSize: 11.5, fontWeight: FontWeight.w600);
    const height = 30.0;
    return Semantics(
      label: semanticLabel,
      child: ExcludeSemantics(
        child: Row(
          children: [
            SizedBox(
              width: 48,
              child: Text(
                label,
                style: AppType.mono.copyWith(color: p.textSecondary, fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final full = constraints.maxWidth;
                  return TweenAnimationBuilder<double>(
                    tween: Tween(begin: AppMotion.reduced(context) ? ratio : 0, end: ratio),
                    duration: AppMotion.of(context, AppMotion.slow + AppMotion.stagger * index.clamp(0, 10)),
                    curve: AppMotion.standard,
                    builder: (context, t, _) {
                      final width = full * t;
                      // The value sits inside a long bar and right of a short one.
                      final inside = t > 0.22;
                      return SizedBox(
                        height: height,
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: p.surfaceSunken,
                                  borderRadius: AppRadius.all(AppRadius.xs),
                                ),
                              ),
                            ),
                            Container(
                              width: width,
                              height: height,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [color.withValues(alpha: 0.95), color.withValues(alpha: 0.65)],
                                ),
                                borderRadius: AppRadius.all(AppRadius.xs),
                              ),
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: AppSpace.xs),
                              child: inside
                                  ? Text(
                                      value,
                                      maxLines: 1,
                                      style: valueStyle.copyWith(
                                        color: readableOn(color),
                                      ),
                                    )
                                  : null,
                            ),
                            if (!inside)
                              Positioned(
                                left: width + AppSpace.xs,
                                top: 0,
                                bottom: 0,
                                child: Center(
                                  child: Text(value, style: valueStyle.copyWith(color: p.textSecondary)),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
