import 'package:quick_remote_shared/quick_remote_shared.dart';

import '../websocket_service.dart' show ConnectionError;

/// Why a command or the connection failed. Services keep no text: the UI
/// turns a failure into words in the user's language (l10n/failure_text.dart).
sealed class Failure {
  const Failure();
}

/// A COMMAND_FAILED status from the PC.
class RemoteFailure extends Failure {
  const RemoteFailure(this.error, {this.info, this.detail});

  /// Reads the status; [error] is null for an older PC (no code) or a newer
  /// one (a code this app does not know).
  factory RemoteFailure.fromStatus(Map<String, dynamic> status) => RemoteFailure(
        RemoteError.fromCode(status['code']),
        info: status['info'] as String?,
        detail: status['detail'] as String?,
      );

  final RemoteError? error;

  /// Untranslated detail (an exception, a program's error code).
  final String? info;

  /// The PC's own Turkish text, shown only when [error] is null.
  final String? detail;
}

/// A failed or lost connection.
class ConnectionFailure extends Failure {
  const ConnectionFailure(this.error, [this.detail]);

  final ConnectionError error;

  /// Untranslated detail (the socket's or the exception's message).
  final String? detail;
}
