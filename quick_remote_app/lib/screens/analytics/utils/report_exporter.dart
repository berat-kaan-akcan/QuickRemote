import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../models/presentation_analytics.dart';
import '../../../../utils/formatters.dart';
import '../../../../utils/ui/app_snackbar.dart';

class ReportExporter {
  /// Converts the presentation analytics to text format and copies it to the clipboard.
  static void copyToClipboard(BuildContext context, PresentationAnalytics analytics) {
    final buffer = StringBuffer();
    buffer.writeln('📊 Sunum Raporu');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('📅 Tarih: ${Formatters.formatDate(analytics.startTime)}');
    buffer.writeln('⏱ Toplam Süre: ${Formatters.formatDuration(analytics.totalDuration)}');
    buffer.writeln('📄 Slayt Sayısı: ${analytics.distinctSlideCount}');
    buffer.writeln('📊 Ort. Süre/Slayt: ${Formatters.formatDuration(analytics.averageTimePerSlide)}');
    buffer.writeln('🔄 Geçiş Sayısı: ${analytics.transitionCount}');
    buffer.writeln('');
    buffer.writeln('Slayt Detayları:');
    buffer.writeln('─────────────────');

    final tps = analytics.timePerSlide;
    final sortedSlides = tps.keys.toList()..sort();
    for (final slide in sortedSlides) {
      buffer.writeln('  Slayt $slide: ${Formatters.formatDuration(tps[slide]!)}');
    }

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    AppSnackbar.show(
      context,
      message: 'Rapor panoya kopyalandı',
      type: SnackbarType.success,
      duration: const Duration(seconds: 2),
    );
  }
}
