import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../l10n/app_language.dart';
import '../../../services/bluetooth/bt_hid_service.dart';
import '../../../utils/ui/app_snackbar.dart';
import '../../../widgets/ui/ui.dart';

/// Makes the phone visible to a computer searching for devices, through
/// Android's own dialog. Otherwise the phone is visible only while Android's
/// Bluetooth settings are open, and the computer would not list it.
class BtMakeVisibleButton extends StatelessWidget {
  const BtMakeVisibleButton({super.key});

  Future<void> _makeVisible(BuildContext context) async {
    final l10n = context.l10n;
    // Android 12+: the Nearby devices group, normally granted already with
    // BLUETOOTH_CONNECT, so no dialog. Below, permission_handler reports it
    // as granted.
    final granted = await Permission.bluetoothAdvertise.request().isGranted;
    final seconds = granted ? await BtHidService.instance.requestDiscoverable() : 0;
    if (!context.mounted) return;
    AppSnackbar.show(
      context,
      message: seconds > 0 ? l10n.btVisibleFor((seconds / 60).ceil()) : l10n.btVisibleRefused,
      type: seconds > 0 ? SnackbarType.success : SnackbarType.warning,
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppButton(
          label: context.l10n.btMakeVisible,
          icon: Icons.visibility_rounded,
          variant: AppButtonVariant.tonal,
          tone: AppTone.info,
          onPressed: () => _makeVisible(context),
        ),
        const SizedBox(height: AppSpace.xs),
        Text(
          context.l10n.btMakeVisibleHint,
          textAlign: TextAlign.center,
          style: AppType.bodySmall.copyWith(color: p.textMuted),
        ),
      ],
    );
  }
}
