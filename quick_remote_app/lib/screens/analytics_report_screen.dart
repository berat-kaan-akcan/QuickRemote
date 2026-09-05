import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/presentation_analytics.dart';

/// A premium-looking analytics report screen that displays
/// per-slide timing data and aggregate statistics.
/// Can be shown as a full screen (from history) or bottom sheet (after presentation).
class AnalyticsReportScreen extends StatelessWidget {
  final PresentationAnalytics analytics;
  final bool isFromHistory;

  const AnalyticsReportScreen({
    super.key,
    required this.analytics,
    this.isFromHistory = false,
  });

  /// Show as a modal bottom sheet (used after presentation ends).
  static Future<void> showAsBottomSheet(
    BuildContext context,
    PresentationAnalytics analytics,
  ) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFF0D0D1A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: AnalyticsReportScreen(
            analytics: analytics,
            isFromHistory: false,
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);
    if (hours > 0) {
      return '${hours}s ${minutes}dk ${seconds}sn';
    } else if (minutes > 0) {
      return '${minutes}dk ${seconds}sn';
    } else {
      return '${seconds}sn';
    }
  }

  String _formatDurationShort(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime dt) {
    const months = [
      '', 'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
    ];
    return '${dt.day} ${months[dt.month]} ${dt.year}, '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  void _copyReport(BuildContext context) {
    final buffer = StringBuffer();
    buffer.writeln('📊 Sunum Raporu');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('📅 Tarih: ${_formatDate(analytics.startTime)}');
    buffer.writeln('⏱ Toplam Süre: ${_formatDuration(analytics.totalDuration)}');
    buffer.writeln('📄 Slayt Sayısı: ${analytics.distinctSlideCount}');
    buffer.writeln('📊 Ort. Süre/Slayt: ${_formatDuration(analytics.averageTimePerSlide)}');
    buffer.writeln('🔄 Geçiş Sayısı: ${analytics.transitionCount}');
    buffer.writeln('');
    buffer.writeln('Slayt Detayları:');
    buffer.writeln('─────────────────');

    final tps = analytics.timePerSlide;
    final sortedSlides = tps.keys.toList()..sort();
    for (final slide in sortedSlides) {
      buffer.writeln('  Slayt $slide: ${_formatDuration(tps[slide]!)}');
    }

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Rapor panoya kopyalandı'),
        backgroundColor: Color(0xFF4CAF50),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tps = analytics.timePerSlide;
    final sortedSlides = tps.keys.toList()..sort();
    final maxDuration = tps.values.isEmpty
        ? const Duration(seconds: 1)
        : tps.values.reduce((a, b) => a > b ? a : b);
    final longest = analytics.longestSlide;
    final shortest = analytics.shortestSlide;

    Widget content = CustomScrollView(
      slivers: [
        // Handle bar (for bottom sheet mode)
        if (!isFromHistory)
          SliverToBoxAdapter(
            child: Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),

        // Title
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6C63FF), Color(0xFF4ECDC4)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.analytics_rounded, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Sunum Raporu',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatDate(analytics.startTime),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Stats cards
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                _StatCard(
                  icon: Icons.timer_rounded,
                  label: 'Toplam Süre',
                  value: _formatDuration(analytics.totalDuration),
                  gradient: const [Color(0xFF6C63FF), Color(0xFF5A54E0)],
                ),
                const SizedBox(width: 10),
                _StatCard(
                  icon: Icons.layers_rounded,
                  label: 'Slayt Sayısı',
                  value: '${analytics.distinctSlideCount}',
                  gradient: const [Color(0xFF4ECDC4), Color(0xFF3DBDB5)],
                ),
                const SizedBox(width: 10),
                _StatCard(
                  icon: Icons.speed_rounded,
                  label: 'Ort/Slayt',
                  value: _formatDurationShort(analytics.averageTimePerSlide),
                  gradient: const [Color(0xFFFF6B6B), Color(0xFFE05555)],
                ),
              ],
            ),
          ),
        ),

        // Transition count
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Row(
                children: [
                  Icon(Icons.swap_horiz_rounded,
                      color: Colors.white.withValues(alpha: 0.6), size: 20),
                  const SizedBox(width: 10),
                  Text(
                    'Toplam Geçiş: ${analytics.transitionCount}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  if (longest != null) ...[
                    Icon(Icons.arrow_upward_rounded,
                        color: const Color(0xFFFF6B6B), size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'S${longest.key}: ${_formatDurationShort(longest.value)}',
                      style: const TextStyle(
                        color: Color(0xFFFF6B6B),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  if (shortest != null && longest?.key != shortest.key) ...[
                    const SizedBox(width: 12),
                    Icon(Icons.arrow_downward_rounded,
                        color: const Color(0xFF4ECDC4), size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'S${shortest.key}: ${_formatDurationShort(shortest.value)}',
                      style: const TextStyle(
                        color: Color(0xFF4ECDC4),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),

        // Section header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Text(
              'Slayt Bazlı Süre',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),

        // Slide bars
        if (sortedSlides.isEmpty)
          SliverToBoxAdapter(
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
          )
        else
          SliverList(
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
                                        _formatDurationShort(duration),
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
                                  _formatDurationShort(duration),
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
          ),

        // Bottom actions
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _copyReport(context),
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    label: const Text('Panoya Kopyala'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text('Tamam'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF6C63FF),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );

    if (isFromHistory) {
      return Scaffold(
        backgroundColor: const Color(0xFF0D0D1A),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text(
            'Sunum Detayı',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        body: content,
      );
    }

    return content;
  }
}

// ─── Stat Card Widget ───
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final List<Color> gradient;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              gradient[0].withValues(alpha: 0.2),
              gradient[1].withValues(alpha: 0.08),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: gradient[0].withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: gradient[0], size: 20),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
