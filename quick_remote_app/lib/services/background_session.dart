import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_background/flutter_background.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Keeps the app running while the phone is locked or the app is in the
/// background (an Android foreground service holding a wake lock), but only
/// while a remote screen or the Bluetooth connect screen is open (Android
/// drops the Bluetooth keyboard registration of a background app without
/// one). Enabled at launch, it would hold the locks and show its notification
/// for as long as the app runs, connected or not.
///
/// Every [acquire] must be paired with one [release].
class BackgroundSession {
  BackgroundSession._();

  /// The notification's text in the UI language, kept current by the app
  /// (main.dart). The plugin reads it once, on the first remote screen.
  static String notificationText = '';

  static FlutterBackgroundAndroidConfig get _config => FlutterBackgroundAndroidConfig(
    notificationTitle: 'QuickRemote',
    notificationText: notificationText,
    notificationImportance: AndroidNotificationImportance.normal,
    notificationIcon: AndroidResource(name: 'ic_launcher', defType: 'mipmap'),
    // The manifest removes REQUEST_IGNORE_BATTERY_OPTIMIZATIONS (Google Play
    // restricts it); the foreground service, its wake lock and Wi-Fi lock keep
    // the session. Without this the plugin fails when the permission is missing.
    shouldRequestBatteryOptimizationsOff: false,
  );

  static int _holders = 0;

  /// Turns true once, when the user refused the notification permission
  /// (Android 13+) and has not been told yet. The foreground service still
  /// runs without it, but its notification may be hidden, so the app says
  /// so once ([NotificationDeniedHost] shows the note). Never blocks anything.
  static final ValueNotifier<bool> notificationDenied = ValueNotifier(false);

  static const _noticeKey = 'notification_denied_notice_shown';

  /// Opens the app's system settings (replaceable in tests).
  static Future<bool> Function() openSettings = openAppSettings;

  /// Called with the answer of the permission request. A refusal is told to
  /// the user once, ever (a preference), not on every start.
  @visibleForTesting
  static Future<void> handleNotificationResult(bool granted) async {
    if (granted) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_noticeKey) ?? false) return;
      await prefs.setBool(_noticeKey, true);
    } catch (_) {
      // Without storage it is told once per run, which the request limits.
    }
    notificationDenied.value = true;
  }

  /// Result of the one initialization attempt per app run (null: not tried).
  /// It asks for the notification permission; a refusal is not asked again
  /// until restart.
  static bool? _available;

  static Future<void> _queue = Future.value();

  /// Completes once the service runs (or could not be started).
  static Future<void> acquire() {
    _holders++;
    return _sync();
  }

  static void release() {
    if (_holders > 0) _holders--;
    _sync();
  }

  // Serialized, because screens open and close faster than the plugin answers.
  static Future<void> _sync() {
    if (!Platform.isAndroid) return Future.value();
    return _queue = _queue.then((_) => _apply()).catchError((Object e) {
      debugPrint('Background execution error: $e');
    });
  }

  static Future<void> _apply() async {
    final wanted = _holders > 0;
    if (wanted == FlutterBackground.isBackgroundExecutionEnabled) return;
    if (!wanted) {
      await FlutterBackground.disableBackgroundExecution();
      return;
    }

    if (_available == null) {
      _available = false; // one attempt per app run, even if it throws
      if (await Permission.notification.isDenied) {
        final status = await Permission.notification.request();
        await handleNotificationResult(status.isGranted);
      }
      _available = await FlutterBackground.initialize(androidConfig: _config);
    }
    if (_available != true) {
      debugPrint('Background execution unavailable: the plugin could not be initialized');
      return;
    }
    // The screen may have closed while the permission dialogs were open.
    if (_holders == 0) return;
    if (!await FlutterBackground.enableBackgroundExecution()) {
      debugPrint('Background execution could not be enabled');
    }
  }
}
