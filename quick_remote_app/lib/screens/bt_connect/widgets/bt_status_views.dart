import 'package:flutter/material.dart';

import '../../../l10n/app_language.dart';
import '../../../theme/app_colors.dart';

/// Shown for a moment before the remote opens.
class BtConnectedView extends StatelessWidget {
  const BtConnectedView({super.key, required this.deviceName});

  final String? deviceName;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.success.withValues(alpha: 0.15),
              border: Border.all(
                color: AppColors.success.withValues(alpha: 0.4),
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.bluetooth_connected_rounded,
              color: AppColors.success,
              size: 64,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            context.l10n.btConnected,
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            deviceName ?? context.l10n.unknownDevice,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.btOpeningRemote,
            style: TextStyle(color: Colors.white38, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

/// The phone cannot act as a Bluetooth keyboard and mouse.
class BtUnsupportedView extends StatelessWidget {
  const BtUnsupportedView({super.key, required this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.bluetooth_disabled_rounded,
              color: Colors.white38,
              size: 72,
            ),
            const SizedBox(height: 24),
            Text(
              context.l10n.btUnsupported,
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message ?? context.l10n.btUnsupportedShort,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 14,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 32),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.wifi_rounded),
              label: Text(context.l10n.btUseWifi),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.bluetoothLight,
                side: const BorderSide(color: AppColors.bluetooth),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Something went wrong; the user can try again.
class BtErrorView extends StatelessWidget {
  const BtErrorView({super.key, required this.message, required this.onRetry});

  final String? message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.danger,
            size: 64,
          ),
          const SizedBox(height: 20),
          Text(
            context.l10n.errorTitle,
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            message ?? context.l10n.btErrorOccurred,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(context.l10n.tryAgain),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.bluetooth,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            ),
          ),
        ],
      ),
    );
  }
}
