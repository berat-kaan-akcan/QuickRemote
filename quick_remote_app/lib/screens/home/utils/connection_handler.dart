import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
  static Future<ConnectAttemptResult> connect(
    BuildContext context, 
    String host, 
    int port, 
    {String pin = ''}
  ) async {
    final ws = context.read<WebSocketService>();
    var connResult = await ws.connect(host, port, pin: pin);

    if (!context.mounted) return ConnectAttemptResult(success: false);

    if (!connResult.success && connResult.error == ConnectionError.certMismatch) {
      final accepted = await _showCertMismatchDialog(context);
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

  static Future<bool> _showCertMismatchDialog(BuildContext context) async {
    return await AppDialog.showConfirm(
      context: context,
      barrierDismissible: false,
      title: 'Güvenlik Uyarısı',
      content: 'Bu cihazın kimliği (sertifikası) daha önce kaydettiğimizden farklı.\n\n'
          'PC\'nizi yeniden kurduysanız veya sertifikayı yenilediyseniz bu normaldir.\n\n'
          'Emin değilseniz bağlanmayın.',
      confirmText: 'Yine de Bağlan ve Güncelle',
      confirmColor: AppPopupTheme.warningColor,
      cancelText: 'İptal Et',
      icon: Icons.shield_rounded,
    );
  }
}
