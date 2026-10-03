import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';

class Formatters {
  static String formatDuration(Duration d, AppLocalizations l10n) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);
    if (hours > 0) {
      return l10n.durationHms(hours, minutes, seconds);
    } else if (minutes > 0) {
      return l10n.durationMs(minutes, seconds);
    } else {
      return l10n.durationS(seconds);
    }
  }

  static String formatDurationShort(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// "3 Ekim 2026 14:05" / "October 3, 2026 14:05"
  static String formatDate(DateTime dt, AppLocalizations l10n) =>
      DateFormat.yMMMMd(l10n.localeName).add_Hm().format(dt);
}
