import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../utils/ui/app_popup_theme.dart';
import '../../../utils/ui/app_snackbar.dart';
import '../../../l10n/app_language.dart';

class ManualConnectData {
  final String host;
  final int port;
  final String pin;

  ManualConnectData({required this.host, required this.port, required this.pin});
}

class ManualConnectDialog extends StatefulWidget {
  final String? defaultIp;
  final String? defaultPort;

  const ManualConnectDialog({super.key, this.defaultIp, this.defaultPort});

  static Future<ManualConnectData?> show(BuildContext context, {String? defaultIp, String? defaultPort}) {
    return showDialog<ManualConnectData>(
      context: context,
      builder: (_) => ManualConnectDialog(defaultIp: defaultIp, defaultPort: defaultPort),
    );
  }

  @override
  State<ManualConnectDialog> createState() => _ManualConnectDialogState();
}

class _ManualConnectDialogState extends State<ManualConnectDialog> {
  late final hostController = TextEditingController(text: widget.defaultIp);
  late final portController = TextEditingController(text: widget.defaultPort ?? '8090');
  final pinController = TextEditingController();

  @override
  void dispose() {
    hostController.dispose();
    portController.dispose();
    pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppPopupTheme.dialogBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppPopupTheme.dialogRadius)),
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
                Text(
                  context.l10n.manualTitle,
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: -0.5),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextField(
              controller: hostController,
              autofocus: widget.defaultIp?.isEmpty ?? true,
              style: const TextStyle(color: Colors.white),
              decoration: AppPopupTheme.inputDecoration(
                context: context,
                labelText: context.l10n.manualIp,
                hintText: '192.168.1.x',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: portController,
              style: const TextStyle(color: Colors.white),
              decoration: AppPopupTheme.inputDecoration(context: context, labelText: 'Port'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: pinController,
              autofocus: widget.defaultIp?.isNotEmpty ?? false,
              onChanged: (_) => HapticFeedback.lightImpact(),
              style: const TextStyle(color: Colors.white),
              decoration: AppPopupTheme.inputDecoration(
                context: context,
                labelText: 'PIN',
                hintText: context.l10n.manualPinHint,
                prefixIcon: Icon(Icons.lock_rounded, color: Colors.white.withValues(alpha: 0.4), size: 20),
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
                final isValid = host.isNotEmpty && pin.length == 6;

                String buttonText = context.l10n.manualConnect;
                if (host.isEmpty) {
                  buttonText = context.l10n.manualWaitingIp;
                } else if (!isValid) {
                  buttonText = context.l10n.manualWaitingPin;
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
                                context,
                                message: context.l10n.manualPortRange,
                                type: SnackbarType.warning,
                              );
                              return;
                            }

                            Navigator.of(context).pop(ManualConnectData(host: host, port: port, pin: pin));
                          }
                        : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppPopupTheme.successColor,
                      disabledBackgroundColor: Colors.white.withValues(alpha: 0.1),
                      foregroundColor: Colors.white,
                      disabledForegroundColor: Colors.white.withValues(alpha: 0.4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppPopupTheme.buttonRadius)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(buttonText, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                        if (isValid) ...[const SizedBox(width: 8), const Icon(Icons.arrow_forward_rounded, size: 20)],
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
  }
}
