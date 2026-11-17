import 'package:flutter/material.dart';

import '../../../l10n/app_language.dart';
import '../../../services/desktop/bluetooth_pairing.dart';
import '../../../widgets/status_snack_bar.dart';
import '../../../widgets/ui/ui.dart';

/// Settings → Bluetooth remote (Windows): when Windows refuses the phone as
/// a keyboard, the phone is removed here and added again in Windows'
/// Bluetooth settings ([BtRepair]). Not yet tried on Windows.
class BtRepairSection extends StatelessWidget {
  const BtRepairSection({super.key, required this.pairing});

  final BluetoothPairing pairing;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.bluetooth_rounded, size: 20, color: p.textSecondary),
            const SizedBox(width: AppSpace.sm),
            Expanded(
              child: Text(l10n.btRepairTitle, style: AppType.titleSmall.copyWith(color: p.textPrimary, fontSize: 14.5)),
            ),
          ],
        ),
        const SizedBox(height: AppSpace.xs),
        Text(l10n.btRepairBody, style: AppType.bodySmall.copyWith(color: p.textSecondary, fontSize: 12)),
        const SizedBox(height: AppSpace.sm),
        AppButton(
          label: l10n.btRepairAction,
          icon: Icons.bluetooth_searching_rounded,
          variant: AppButtonVariant.tonal,
          expand: false,
          height: 40,
          onPressed: () => _pick(context),
        ),
      ],
    );
  }

  Future<void> _pick(BuildContext context) async {
    final repair = BtRepair(pairing);
    final device = await showDialog<PairedDevice>(
      context: context,
      builder: (context) => _PickDeviceDialog(devices: repair.candidates()),
    );
    if (device == null || !context.mounted) return;
    final outcome = await repair.repair(device);
    if (!context.mounted) return;
    final l10n = context.l10n;
    switch (outcome) {
      case BtRepairOutcome.removed:
        showStatusSnackBar(context, l10n.btRepairRemoved(device.label), kind: StatusKind.success);
      case BtRepairOutcome.removedSettingsClosed:
        showStatusSnackBar(context, l10n.btRepairRemovedNoSettings(device.label), kind: StatusKind.warning);
      case BtRepairOutcome.removeFailed:
        showStatusSnackBar(context, l10n.btRepairRemoveFailed(device.label), kind: StatusKind.error);
    }
  }
}

class _PickDeviceDialog extends StatelessWidget {
  const _PickDeviceDialog({required this.devices});

  final List<PairedDevice> devices;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;
    return AlertDialog(
      title: Text(l10n.btRepairPickTitle, style: AppType.title.copyWith(color: p.textPrimary, fontSize: 18)),
      // A fixed width: AlertDialog measures its content's intrinsic size,
      // which a list view cannot give.
      content: SizedBox(
        width: 400,
        child: devices.isEmpty
            ? Text(l10n.btRepairNone, style: AppType.body.copyWith(color: p.textSecondary))
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.btRepairPickBody, style: AppType.bodySmall.copyWith(color: p.textSecondary)),
                  const SizedBox(height: AppSpace.sm),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (final device in devices)
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(
                                device.isPhone ? Icons.smartphone_rounded : Icons.bluetooth_rounded,
                                color: device.isPhone ? p.primaryText : p.textSecondary,
                              ),
                              title: Text(
                                device.label,
                                style: AppType.titleSmall.copyWith(color: p.textPrimary, fontSize: 14.5),
                              ),
                              subtitle: Text(
                                device.addressText,
                                style: AppType.bodySmall.copyWith(color: p.textSecondary, fontSize: 12),
                              ),
                              onTap: () => Navigator.of(context).pop(device),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
      actions: [
        AppButton(
          label: l10n.close,
          variant: AppButtonVariant.tonal,
          expand: false,
          height: 44,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
