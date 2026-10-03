import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quick_remote_shared/quick_remote_shared.dart';

import '../../../../services/websocket_service.dart';
import '../../../l10n/app_language.dart';
import '../../../l10n/failure_text.dart';
import '../../../utils/ui/app_dialog.dart';
import '../../../utils/ui/app_popup_theme.dart';

class ConnectAttemptResult {
  final bool success;
  final String? errorMessage;
  final bool wasCancelled;

  ConnectAttemptResult({
    required this.success,
    this.errorMessage,
    this.wasCancelled = false,
  });
}

class ConnectionHandler {
  /// Connects to the PC, handling TOFU certificate mismatches via dialog automatically.
  /// With a [certFingerprint] from the QR code a mismatch is final (no dialog).
  static Future<ConnectAttemptResult> connect(
    BuildContext context,
    String host,
    int port,
    {String pin = '', String? certFingerprint}
  ) async {
    final ws = context.read<WebSocketService>();
    var connResult = await ws.connect(host, port, pin: pin, certFingerprint: certFingerprint);

    if (!context.mounted) return ConnectAttemptResult(success: false);

    final needsApproval = connResult.error == ConnectionError.certMismatch ||
        connResult.error == ConnectionError.unverified;
    if (!connResult.success && needsApproval && connResult.newFingerprint != null) {
      final code = PairingPayload.verificationCode(connResult.newFingerprint!);
      final accepted = connResult.error == ConnectionError.unverified
          ? await _showVerifyDialog(context, code)
          : await _showCertMismatchDialog(context, code);
      if (!context.mounted) return ConnectAttemptResult(success: false);

      if (accepted && connResult.newFingerprint != null) {
        connResult = await ws.acceptCertificateAndReconnect(
          host,
          connResult.newFingerprint!,
          port: port,
          pin: pin,
        );
        if (!context.mounted) return ConnectAttemptResult(success: false);
      } else {
        return ConnectAttemptResult(success: false, wasCancelled: true);
      }
    }

    if (connResult.success) {
      return ConnectAttemptResult(success: true);
    } else {
      return ConnectAttemptResult(
        success: false,
        errorMessage: context.l10n.connectionError(connResult.error, connResult.detail),
      );
    }
  }

  /// First connection without the QR code: nothing vouches for the PC yet.
  static Future<bool> _showVerifyDialog(BuildContext context, String code) async {
    return await AppDialog.showConfirm(
      context: context,
      barrierDismissible: false,
      title: context.l10n.verifyTitle,
      content: context.l10n.verifyContent(code),
      confirmText: context.l10n.verifyConfirm,
      confirmColor: AppPopupTheme.successColor,
      cancelText: context.l10n.cancelAction,
      icon: Icons.verified_user_rounded,
    );
  }

  static Future<bool> _showCertMismatchDialog(BuildContext context, String code) async {
    return await AppDialog.showConfirm(
      context: context,
      barrierDismissible: false,
      title: context.l10n.certWarningTitle,
      content: context.l10n.certWarningContent(code),
      confirmText: context.l10n.certWarningConfirm,
      confirmColor: AppPopupTheme.warningColor,
      cancelText: context.l10n.cancelAction,
      icon: Icons.shield_rounded,
    );
  }
}
