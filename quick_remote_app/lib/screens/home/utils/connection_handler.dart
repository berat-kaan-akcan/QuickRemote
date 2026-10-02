import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quick_remote_shared/quick_remote_shared.dart';

import '../../../../services/websocket_service.dart';
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
        errorMessage: connResult.message ?? 'Bağlantı kurulamadı.\n$host:$port adresini kontrol edin.'
      );
    }
  }

  /// First connection without the QR code: nothing vouches for the PC yet.
  static Future<bool> _showVerifyDialog(BuildContext context, String code) async {
    return await AppDialog.showConfirm(
      context: context,
      barrierDismissible: false,
      title: 'Güvenlik Kodunu Karşılaştırın',
      content: 'Bu PC ile ilk kez bağlanıyorsunuz. PC ekranındaki güvenlik kodu şu olmalı:\n\n'
          '$code\n\n'
          'Kodlar aynı değilse bağlanmayın: ağdaki başka bir cihaz PC gibi davranıyor olabilir. '
          'QR kodu okutarak bu adımı atlayabilirsiniz.',
      confirmText: 'Kodlar Aynı, Bağlan',
      confirmColor: AppPopupTheme.successColor,
      cancelText: 'İptal Et',
      icon: Icons.verified_user_rounded,
    );
  }

  static Future<bool> _showCertMismatchDialog(BuildContext context, String code) async {
    return await AppDialog.showConfirm(
      context: context,
      barrierDismissible: false,
      title: 'Güvenlik Uyarısı',
      content: 'Bu cihazın kimliği (sertifikası) daha önce kaydettiğimizden farklı.\n\n'
          'PC\'nizi yeniden kurduysanız veya sertifikayı yenilediyseniz bu normaldir. '
          'PC ekranındaki güvenlik kodu şu olmalı:\n\n'
          '$code\n\n'
          'Kodlar aynı değilse bağlanmayın.',
      confirmText: 'Yine de Bağlan ve Güncelle',
      confirmColor: AppPopupTheme.warningColor,
      cancelText: 'İptal Et',
      icon: Icons.shield_rounded,
    );
  }
}
