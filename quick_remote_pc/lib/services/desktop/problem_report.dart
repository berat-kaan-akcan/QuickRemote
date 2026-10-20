import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:quick_remote_shared/quick_remote_shared.dart';

import '../../app_version.dart';
import '../../l10n/app_localizations.dart';
import 'update_checker.dart' show openInBrowser;

/// Settings → Troubleshooting: saving the local log ([AppLog]) where the
/// user picks, and a GitHub issue filled in with the version, the platform
/// and the programs this PC controls. Nothing is uploaded.
class ProblemReport {
  ProblemReport._();

  static String get platform =>
      '${Platform.operatingSystem} (${Platform.operatingSystemVersion})';

  /// The programs this build controls (InputSimulator would create the input
  /// devices just to say so).
  static String get presenters =>
      Platform.isWindows ? 'PowerPoint, WPS' : 'Impress, WPS';

  /// The lines above the log in an exported file.
  static String get header =>
      'QuickRemote PC $appVersion\nPlatform: $platform\nPrograms: $presenters\n\n';

  @visibleForTesting
  static String fileName(DateTime now) {
    String two(int n) => n.toString().padLeft(2, '0');
    return 'quickremote-pc-log-${now.year}-${two(now.month)}-${two(now.day)}-${two(now.hour)}${two(now.minute)}.txt';
  }

  /// Asks where to save the log and writes it there: null when the user
  /// cancelled, else whether it was written.
  static Future<bool?> exportLog() async {
    final FileSaveLocation? location;
    try {
      location = await getSaveLocation(
        suggestedName: fileName(DateTime.now()),
        acceptedTypeGroups: const [
          XTypeGroup(label: 'Log', extensions: ['txt', 'log']),
        ],
      );
    } catch (e) {
      debugPrint('Log export: no save dialog: $e');
      return false;
    }
    if (location == null) return null;
    try {
      await File(location.path).writeAsString(header + await AppLog.collect());
      return true;
    } catch (e) {
      debugPrint('Log export failed: $e');
      return false;
    }
  }

  static Uri issueUrl(AppLocalizations l10n) => AppLog.issueUrl(
    title: '[PC] ',
    body: l10n.issueBody(appVersion, platform, presenters),
  );

  /// Opens the new issue in the browser.
  static Future<void> openIssue(AppLocalizations l10n) =>
      openInBrowser(issueUrl(l10n));
}
