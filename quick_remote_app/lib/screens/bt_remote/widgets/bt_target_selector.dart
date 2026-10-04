import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../services/bluetooth/bt_key_mapping.dart';
import '../../../l10n/app_language.dart';
import '../../../theme/app_colors.dart';

class BtTargetSelector extends StatelessWidget {
  const BtTargetSelector({super.key, required this.target, required this.onChanged});

  final BtTarget target;
  final ValueChanged<BtTarget> onChanged;

  /// Over Bluetooth the phone only sends keyboard shortcuts, which differ per
  /// presentation program, so the user picks the target.
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          context.l10n.btTarget,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SegmentedButton<BtTarget>(
            segments: const [
              ButtonSegment(value: BtTarget.powerpoint, label: Text('PowerPoint')),
              ButtonSegment(value: BtTarget.impress, label: Text('Impress')),
              ButtonSegment(value: BtTarget.wps, label: Text('WPS')),
            ],
            selected: {target},
            showSelectedIcon: false,
            onSelectionChanged: (s) {
              HapticFeedback.selectionClick();
              onChanged(s.first);
            },
            style: SegmentedButton.styleFrom(
              foregroundColor: Colors.white54,
              selectedForegroundColor: Colors.white,
              selectedBackgroundColor: AppColors.bluetooth.withValues(alpha: 0.5),
              side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
              visualDensity: VisualDensity.compact,
              textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}
