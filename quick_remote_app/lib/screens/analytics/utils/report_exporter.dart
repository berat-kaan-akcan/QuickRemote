import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../models/presentation_analytics.dart';
import '../../../utils/formatters.dart';
import '../../../utils/ui/app_snackbar.dart';
import '../../../l10n/app_language.dart';

class ReportExporter {
  /// Converts the presentation analytics to text format and copies it to the clipboard.
  static void copyToClipboard(BuildContext context, PresentationAnalytics analytics) {
    final l10n = context.l10n;
    final buffer = StringBuffer();
    buffer.writeln('📊 ${l10n.reportTitle}');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('📅 ${l10n.reportDate}: ${Formatters.formatDate(analytics.startTime, l10n)}');
    buffer.writeln('⏱ ${l10n.totalTime}: ${Formatters.formatDuration(analytics.totalDuration, l10n)}');
    buffer.writeln('📄 ${l10n.slideCountLabel}: ${analytics.distinctSlideCount}');
    buffer.writeln('📊 ${l10n.reportAvgPerSlide}: ${Formatters.formatDuration(analytics.averageTimePerSlide, l10n)}');
    buffer.writeln('🔄 ${l10n.reportTransitions}: ${analytics.transitionCount}');
    buffer.writeln('');
    buffer.writeln('${l10n.reportSlideDetails}:');
    buffer.writeln('─────────────────');

    final tps = analytics.timePerSlide;
    final sortedSlides = tps.keys.toList()..sort();
    for (final slide in sortedSlides) {
      buffer.writeln('  ${l10n.reportSlide(slide)}: ${Formatters.formatDuration(tps[slide]!, l10n)}');
    }

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    AppSnackbar.show(
      context,
      message: l10n.reportCopied,
      type: SnackbarType.success,
      duration: const Duration(seconds: 2),
    );
  }
}
