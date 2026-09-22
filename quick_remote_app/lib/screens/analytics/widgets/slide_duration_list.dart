import 'package:flutter/material.dart';
import '../../../../models/presentation_analytics.dart';
import '../../../../utils/formatters.dart';

class SlideDurationList extends StatelessWidget {
  final PresentationAnalytics analytics;

  const SlideDurationList({super.key, required this.analytics});

  @override
  Widget build(BuildContext context) {
    final tps = analytics.timePerSlide;
    final sortedSlides = tps.keys.toList()..sort();
    
    if (sortedSlides.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Center(
            child: Text(
              'Slayt verisi bulunamadı',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 14,
              ),
            ),
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

          Color barColor;
          if (isLongest) {
            barColor = const Color(0xFFFF6B6B);
          } else if (isShortest) {
            barColor = const Color(0xFF4ECDC4);
          } else {
            barColor = const Color(0xFF6C63FF);
          }

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 50,
                  child: Text(
                    'S$slideNum',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                Expanded(
                  child: Stack(
                    children: [
                      Container(
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: ratio.clamp(0.03, 1.0),
                        child: Container(
                          height: 28,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                barColor.withValues(alpha: 0.8),
                                barColor.withValues(alpha: 0.5),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 8),
                          child: ratio > 0.15
                              ? Text(
                                  Formatters.formatDurationShort(duration),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    fontFeatures: [FontFeature.tabularFigures()],
                                  ),
                                )
                              : null,
                        ),
                      ),
                      if (ratio <= 0.15)
                        Positioned(
                          left: (ratio.clamp(0.03, 1.0) * MediaQuery.of(context).size.width * 0.65) + 8,
                          top: 6,
                          child: Text(
                            Formatters.formatDurationShort(duration),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        childCount: sortedSlides.length,
      ),
    );
  }
}
