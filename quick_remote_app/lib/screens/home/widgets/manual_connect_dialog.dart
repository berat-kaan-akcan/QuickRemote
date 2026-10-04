import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../utils/ui/app_popup_theme.dart';
import '../../../utils/ui/app_snackbar.dart';
import '../../../l10n/app_language.dart';
import '../../../widgets/ui/ui.dart';

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
    return AppPopupTheme.showAppDialog<ManualConnectData>(
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
    final p = context.palette;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: AppSpace.lg, vertical: AppSpace.xl),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppPopupTheme.maxWidth),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(AppSpace.xl, AppSpace.xl, AppSpace.xl, AppSpace.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  IconBadge(icon: Icons.lan_rounded, color: p.primaryText, size: 44),
                  const SizedBox(width: AppSpace.sm),
                  Expanded(
                    child: Text(
                      context.l10n.manualTitle,
                      style: AppType.title.copyWith(color: p.textPrimary, fontSize: 20),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.xl),
              TextField(
                controller: hostController,
                autofocus: widget.defaultIp?.isEmpty ?? true,
                style: AppType.body.copyWith(color: p.textPrimary),
                decoration: AppPopupTheme.inputDecoration(
                  context: context,
                  labelText: context.l10n.manualIp,
                  hintText: '192.168.1.x',
                  prefixIcon: const Icon(Icons.computer_rounded, size: 20),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: AppSpace.sm),
              TextField(
                controller: portController,
                style: AppType.body.copyWith(color: p.textPrimary),
                decoration: AppPopupTheme.inputDecoration(
                  context: context,
                  labelText: 'Port',
                  prefixIcon: const Icon(Icons.numbers_rounded, size: 20),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: AppSpace.sm),
              TextField(
                controller: pinController,
                autofocus: widget.defaultIp?.isNotEmpty ?? false,
                onChanged: (_) => HapticFeedback.lightImpact(),
                style: AppType.title.copyWith(color: p.textPrimary, letterSpacing: 6, fontSize: 20),
                decoration: AppPopupTheme.inputDecoration(
                  context: context,
                  labelText: 'PIN',
                  hintText: context.l10n.manualPinHint,
                  prefixIcon: const Icon(Icons.lock_rounded, size: 20),
                ).copyWith(hintStyle: AppType.body.copyWith(color: p.textMuted, letterSpacing: 0)),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                maxLength: 6,
              ),
              const SizedBox(height: AppSpace.md),
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

                  return AppButton(
                    label: buttonText,
                    trailingIcon: isValid ? Icons.arrow_forward_rounded : null,
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
                  );
                },
              ),
              const SizedBox(height: AppSpace.xs),
              AppButton(
                label: context.l10n.cancel,
                variant: AppButtonVariant.ghost,
                tone: AppTone.neutral,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
