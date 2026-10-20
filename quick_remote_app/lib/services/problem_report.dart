import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:quick_remote_shared/quick_remote_shared.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_version.dart';
import '../l10n/app_localizations.dart';

/// Ayarlar → Help: sharing the local log ([AppLog]) through Android's share
/// sheet and a GitHub issue filled in with the version, the platform and the
/// programs. Nothing is uploaded by the app.
class ProblemReport {
  ProblemReport._();

  static String get platform =>
      '${Platform.operatingSystem} (${Platform.operatingSystemVersion})';

  /// The lines above the log in a shared file.
  @visibleForTesting
  static String header({
    required String presenters,
    required String btTarget,
  }) =>
      'QuickRemote $appVersion (phone)\nPlatform: $platform\nPC programs: $presenters\nBluetooth target: $btTarget\n\n';

  @visibleForTesting
  static String fileName(DateTime now) {
    String two(int n) => n.toString().padLeft(2, '0');
    return 'quickremote-log-${now.year}-${two(now.month)}-${two(now.day)}-${two(now.hour)}${two(now.minute)}.txt';
  }

  /// Opens the share sheet with the log as a text file: null when there is
  /// no log yet, else whether the sheet opened.
  static Future<bool?> shareLog({
    required String presenters,
    required String btTarget,
  }) async {
    try {
      final log = await AppLog.collect();
      if (log.trim().isEmpty) return null;
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/${fileName(DateTime.now())}');
      await file.writeAsString(
        header(presenters: presenters, btTarget: btTarget) + log,
      );
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'text/plain')],
          subject: 'QuickRemote log',
        ),
      );
      return true;
    } catch (e) {
      debugPrint('Log share failed: $e');
      return false;
    }
  }

  static Uri issueUrl(
    AppLocalizations l10n, {
    required String presenters,
    required String btTarget,
  }) => AppLog.issueUrl(
    title: '[Android] ',
    body: l10n.issueBody(appVersion, platform, presenters, btTarget),
  );

  /// Opens the new issue in the browser; false when none could.
  static Future<bool> openIssue(
    AppLocalizations l10n, {
    required String presenters,
    required String btTarget,
  }) async {
    try {
      return await launchUrl(
        issueUrl(l10n, presenters: presenters, btTarget: btTarget),
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      debugPrint('Issue link failed: $e');
      return false;
    }
  }
}
