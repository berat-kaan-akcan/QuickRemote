import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/websocket_server.dart';
import '../../../l10n/app_language.dart';
import '../../../widgets/ui/ui.dart';

class PublicNetworkWarningDialog extends StatefulWidget {
  final WebSocketServer server;

  const PublicNetworkWarningDialog({super.key, required this.server});

  @override
  State<PublicNetworkWarningDialog> createState() => _PublicNetworkWarningDialogState();
}

class _PublicNetworkWarningDialogState extends State<PublicNetworkWarningDialog> {
  bool _dontShowAgain = false;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AlertDialog(
      icon: Center(child: IconBadge(icon: Icons.wifi_tethering_rounded, color: p.warning, size: 56)),
      title: Text(
        context.l10n.publicNetworkTitle,
        textAlign: TextAlign.center,
        style: AppType.title.copyWith(color: p.textPrimary, fontSize: 20),
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              Platform.isLinux
                  ? context.l10n.publicNetworkLinux
                  : context.l10n.publicNetworkWindows,
              style: AppType.body.copyWith(color: p.textSecondary, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: AppSpace.md),
            AppButton(
              label: context.l10n.openNetworkSettings,
              icon: Icons.settings_rounded,
              variant: AppButtonVariant.outline,
              tone: AppTone.primary,
              height: 44,
              onPressed: () => widget.server.openNetworkSettings(),
            ),
            const SizedBox(height: AppSpace.md),
            Row(
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: _dontShowAgain,
                    onChanged: (val) {
                      setState(() => _dontShowAgain = val ?? false);
                    },
                  ),
                ),
                const SizedBox(width: AppSpace.sm),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _dontShowAgain = !_dontShowAgain),
                    child: Text(
                      context.l10n.dontShowAgain,
                      style: AppType.bodySmall.copyWith(color: p.textSecondary),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        AppButton(
          label: context.l10n.stopServer,
          variant: AppButtonVariant.ghost,
          tone: AppTone.neutral,
          expand: false,
          height: 44,
          onPressed: () {
            if (context.mounted) Navigator.of(context).pop(false);
          },
        ),
        AppButton(
          label: context.l10n.continueAction,
          variant: AppButtonVariant.solid,
          tone: AppTone.warning,
          expand: false,
          height: 44,
          onPressed: () async {
            if (_dontShowAgain) {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('hide_public_network_warning', true);
            }
            if (context.mounted) Navigator.of(context).pop(true);
          },
        ),
      ],
    );
  }
}
