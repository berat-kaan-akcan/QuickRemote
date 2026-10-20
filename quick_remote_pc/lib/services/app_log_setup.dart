import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:quick_remote_shared/quick_remote_shared.dart';

/// Sends `debugPrint` and every uncaught error to [AppLog], whose files go
/// into [directory]. Called once in `main()`, after the binding exists; the
/// call sites keep using `debugPrint`.
///
/// No `runZonedGuarded`: [PlatformDispatcher.onError] already gets the
/// errors no zone handled, and a guarded zone around `runApp` only makes
/// Flutter warn about zone mismatches.
void installAppLog(Future<Directory> directory) {
  final console = debugPrint;
  unawaited(AppLog.init(directory, console: (line) => console(line)));
  debugPrint = (String? message, {int? wrapWidth}) {
    if (message != null) AppLog.log(message);
  };

  FlutterError.onError = (details) {
    final library = details.library == null ? '' : ' (${details.library})';
    final context = details.context == null ? '' : ', ${details.context}';
    AppLog.error('Flutter$library$context', details.exception, details.stack);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    AppLog.error('uncaught', error, stack);
    return true;
  };
  // Errors the dispatcher did not take (e.g. outside Flutter's zone).
  final port = RawReceivePort((Object? pair) {
    if (pair is List && pair.length == 2) {
      final stack = pair[1];
      AppLog.error(
        'isolate',
        pair[0] ?? 'unknown error',
        stack is String ? StackTrace.fromString(stack) : null,
      );
    }
  });
  Isolate.current.addErrorListener(port.sendPort);

  // What is still queued reaches the disk before the app may be killed.
  AppLifecycleListener(
    onHide: () => unawaited(AppLog.flush()),
    onDetach: () => unawaited(AppLog.flush()),
  );
}
