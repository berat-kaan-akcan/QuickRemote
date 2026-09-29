import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_background/flutter_background.dart';
import 'package:permission_handler/permission_handler.dart';

/// Keeps the app running while the phone is locked or the app is in the
/// background (an Android foreground service holding a wake lock), but only
/// while a remote screen is open. Enabled at launch, it would hold the locks
/// and show its notification for as long as the app runs, connected or not.
///
/// Every [acquire] must be paired with one [release].
class BackgroundSession {
  BackgroundSession._();

  static const _config = FlutterBackgroundAndroidConfig(
    notificationTitle: 'QuickRemote',
    notificationText: 'Arka planda bağlantı devam ediyor...',
    notificationImportance: AndroidNotificationImportance.normal,
    notificationIcon: AndroidResource(name: 'ic_launcher', defType: 'mipmap'),
  );

  static int _holders = 0;

  /// Result of the one initialization attempt per app run (null: not tried).
  /// It asks for the notification permission and the battery optimization
  /// exemption the plugin requires; a refusal is not asked again until restart.
  static bool? _available;

  static Future<void> _queue = Future.value();

  static void acquire() {
    _holders++;
    _sync();
  }

  static void release() {
    if (_holders > 0) _holders--;
    _sync();
  }

  // Serialized, because screens open and close faster than the plugin answers.
  static void _sync() {
    if (!Platform.isAndroid) return;
    _queue = _queue.then((_) => _apply()).catchError((Object e) {
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
        await Permission.notification.request();
      }
      _available = await FlutterBackground.initialize(androidConfig: _config);
    }
    if (_available != true) {
      debugPrint('Background execution unavailable: battery optimization exemption not granted');
      return;
    }
    // The screen may have closed while the permission dialogs were open.
    if (_holders == 0) return;
    if (!await FlutterBackground.enableBackgroundExecution()) {
      debugPrint('Background execution could not be enabled');
    }
  }
}
