import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../services/bluetooth/bt_key_mapping.dart';
import '../../../l10n/app_language.dart';
import '../../../widgets/ui/ui.dart';

class BtTargetSelector extends StatelessWidget {
  const BtTargetSelector({super.key, required this.target, required this.onChanged});

  final BtTarget target;
  final ValueChanged<BtTarget> onChanged;

  /// Over Bluetooth the phone only sends keyboard shortcuts, which differ per
  /// presentation program, so the user picks the target.
  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      children: [
        Text(
          context.l10n.btTarget,
          style: AppType.labelSmall.copyWith(color: p.textMuted),
        ),
        const SizedBox(width: AppSpace.xs),
        Expanded(
          child: AppSegmented<BtTarget>(
            height: 40,
            color: p.info,
            segments: const [
              AppSegment(value: BtTarget.powerpoint, label: 'PowerPoint'),
              AppSegment(value: BtTarget.impress, label: 'Impress'),
              AppSegment(value: BtTarget.wps, label: 'WPS'),
            ],
            selected: target,
            onChanged: (value) {
              HapticFeedback.selectionClick();
              onChanged(value);
            },
          ),
        ),
      ],
    );
  }
}
