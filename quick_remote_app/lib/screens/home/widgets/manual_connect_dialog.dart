import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../utils/ui/app_bottom_sheet.dart';
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

    return AppBottomSheet.show<ManualConnectData>(
      context: context,
      builder: (ctx) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: AppBottomSheet.buildTitle('Manuel Bağlantı', icon: Icons.link_rounded),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: hostController,
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
              onChanged: (_) => HapticFeedback.lightImpact(),
              style: const TextStyle(color: Colors.white),
              decoration: AppPopupTheme.inputDecoration(
                context: ctx,
                labelText: 'PIN',
                hintText: 'PC ekranındaki 4 haneli PIN',
                prefixIcon: Icon(
                  Icons.lock_rounded,
                  color: Colors.white.withValues(alpha: 0.4),
                  size: 20,
                ),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: () {
                  final host = hostController.text.trim();
                  final port = int.tryParse(portController.text.trim()) ?? 0;
                  final pin = pinController.text.trim();

                  if (host.isEmpty) return;

                  if (port < 1 || port > 65535) {
                    AppSnackbar.show(
                      ctx,
                      message: 'Port 1-65535 arası olmalı',
                      type: SnackbarType.warning,
                    );
                    return;
                  }

                  Navigator.of(ctx).pop(ManualConnectData(host: host, port: port, pin: pin));
                },
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF005B96),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppPopupTheme.buttonRadius),
                  ),
                ),
                child: const Text(
                  'Bağlan',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
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
