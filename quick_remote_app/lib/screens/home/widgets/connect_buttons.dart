import 'dart:io';
import 'package:flutter/material.dart';

import '../../../l10n/app_language.dart';
import '../../../theme/app_colors.dart';

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
        Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.blue, AppColors.accent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.blue.withValues(alpha: 0.4),
                blurRadius: 16,
                spreadRadius: 2,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ElevatedButton.icon(
            onPressed: connecting ? null : onScan,
            icon: connecting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : const Icon(
                    Icons.qr_code_scanner_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
            label: Text(
              connecting
                  ? context.l10n.homeConnecting
                  : context.l10n.homeConnectQr,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),

        if (Platform.isAndroid) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.bluetoothLight, width: 2),
            ),
            child: ElevatedButton.icon(
              onPressed: connecting ? null : onBluetooth,
              icon: const Icon(
                Icons.bluetooth_rounded,
                color: AppColors.bluetoothLight,
                size: 24,
              ),
              label: Text(
                context.l10n.homeConnectBluetooth,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.bluetoothLight,
                  letterSpacing: 0.5,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
