import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../utils/ui/app_popup_theme.dart';
import '../../../utils/ui/app_snackbar.dart';

class ManualConnectData {
  final String host;
  final int port;
  final String pin;

  ManualConnectData({required this.host, required this.port, required this.pin});
}

class ManualConnectDialog extends StatelessWidget {
  final String? defaultIp;
  final String? defaultPort;

  const ManualConnectDialog({super.key, this.defaultIp, this.defaultPort});

  static Future<ManualConnectData?> show(BuildContext context, {String? defaultIp, String? defaultPort}) {
    final hostController = TextEditingController(text: defaultIp);
    final portController = TextEditingController(text: defaultPort ?? '8090');
    final pinController = TextEditingController();

    return showDialog<ManualConnectData>(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: AppPopupTheme.dialogBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppPopupTheme.dialogRadius),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.link_rounded, color: Colors.white, size: 24),
                    const SizedBox(width: 8),
                    const Text(
                      'Manuel Bağlantı',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
            TextField(
              controller: hostController,
              autofocus: defaultIp == null || defaultIp.isEmpty,
              style: const TextStyle(color: Colors.white),
              decoration: AppPopupTheme.inputDecoration(
                context: ctx,
                labelText: 'IP Adresi',
                hintText: '192.168.1.x',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: portController,
              style: const TextStyle(color: Colors.white),
              decoration: AppPopupTheme.inputDecoration(
                context: ctx,
                labelText: 'Port',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: pinController,
              autofocus: defaultIp != null && defaultIp.isNotEmpty,
              onChanged: (_) => HapticFeedback.lightImpact(),
              style: const TextStyle(color: Colors.white),
              decoration: AppPopupTheme.inputDecoration(
                context: ctx,
                labelText: 'PIN',
                hintText: 'PC ekranındaki PIN',
                prefixIcon: Icon(
                  Icons.lock_rounded,
                  color: Colors.white.withValues(alpha: 0.4),
                  size: 20,
                ),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              maxLength: 6,
            ),
            const SizedBox(height: 20),
            AnimatedBuilder(
              animation: Listenable.merge([hostController, pinController]),
              builder: (context, child) {
                final host = hostController.text.trim();
                final pin = pinController.text.trim();
                // 6 digits; PCs running an older version show 4.
                final isValid = host.isNotEmpty && (pin.length == 6 || pin.length == 4);

                String buttonText = 'Bağlan';
                if (host.isEmpty) {
                  buttonText = 'IP Bekleniyor...';
                } else if (!isValid) {
                  buttonText = 'PIN Bekleniyor...';
                }

                return SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: isValid
                        ? () {
                            final port = int.tryParse(portController.text.trim()) ?? 0;

                            if (port < 1 || port > 65535) {
                              AppSnackbar.show(
                                ctx,
                                message: 'Port 1-65535 arası olmalı',
                                type: SnackbarType.warning,
                              );
                              return;
                            }

                            Navigator.of(ctx).pop(ManualConnectData(
                                host: host, port: port, pin: pin));
                          }
                        : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppPopupTheme.successColor,
                      disabledBackgroundColor: Colors.white.withValues(alpha: 0.1),
                      foregroundColor: Colors.white,
                      disabledForegroundColor: Colors.white.withValues(alpha: 0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppPopupTheme.buttonRadius),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          buttonText,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                        ),
                        if (isValid) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_rounded, size: 20),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Bu widget artık doğrudan kullanılmıyor.
    // ManualConnectDialog.show() static metodu ile bottom sheet açılır.
    return const SizedBox.shrink();
  }
}
