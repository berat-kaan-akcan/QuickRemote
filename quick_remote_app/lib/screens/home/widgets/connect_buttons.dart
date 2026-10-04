import 'dart:io';
import 'package:flutter/material.dart';

import '../../../l10n/app_language.dart';
import '../../../widgets/ui/ui.dart';

/// Connect with the QR code or, on Android, over Bluetooth.
class ConnectButtons extends StatelessWidget {
  const ConnectButtons({
    super.key,
    required this.connecting,
    required this.onScan,
    required this.onBluetooth,
  });

  final bool connecting;
  final VoidCallback onScan;
  final VoidCallback onBluetooth;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppButton(
          label: connecting ? context.l10n.homeConnecting : context.l10n.homeConnectQr,
          icon: Icons.qr_code_scanner_rounded,
          trailingIcon: connecting ? null : Icons.arrow_forward_rounded,
          loading: connecting,
          height: 58,
          onPressed: onScan,
        ),
        if (Platform.isAndroid) ...[
          const SizedBox(height: AppSpace.sm),
          AppButton(
            label: context.l10n.homeConnectBluetooth,
            icon: Icons.bluetooth_rounded,
            variant: AppButtonVariant.tonal,
            tone: AppTone.info,
            height: 58,
            onPressed: connecting ? null : onBluetooth,
          ),
        ],
      ],
    );
  }
}
