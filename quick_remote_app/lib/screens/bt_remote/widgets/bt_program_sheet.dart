import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../l10n/app_language.dart';
import '../../../providers/settings_provider.dart';
import '../../../services/bluetooth/bt_key_mapping.dart';
import '../../../utils/ui/app_bottom_sheet.dart';
import '../../../widgets/ui/ui.dart';
import '../../remote/widgets/program_sheet.dart';

/// The program whose shortcuts the Bluetooth remote sends, asked on every
/// connection and opened again from the header's program line. Over
/// Bluetooth the computer cannot tell it, so the user picks it here.
class BtProgramSheet {
  BtProgramSheet._();

  /// [closeOnPick] closes the sheet with the tap that picks a program, as
  /// when it is asked on connecting.
  static Future<void> show(BuildContext context, {bool closeOnPick = false}) {
    return AppBottomSheet.show(context: context, builder: (ctx) => _BtProgramList(closeOnPick: closeOnPick));
  }
}

class _BtProgramList extends StatelessWidget {
  const _BtProgramList({required this.closeOnPick});

  final bool closeOnPick;

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final p = context.palette;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(context.l10n.programSheetTitle, style: AppType.title.copyWith(color: p.textPrimary, fontSize: 20)),
        const SizedBox(height: AppSpace.xs),
        Text(context.l10n.btProgramSheetBody, style: AppType.bodySmall.copyWith(color: p.textSecondary)),
        const SizedBox(height: AppSpace.md),
        for (final target in BtTarget.values) ...[
          ProgramOption(
            program: target.name,
            selected: target == settings.btTarget,
            // Impress has no laser, highlighter or eraser shortcut.
            status: target == BtTarget.impress ? context.l10n.btToolsImpress : context.l10n.btToolsFull,
            onTap: () {
              HapticFeedback.selectionClick();
              settings.setBtTarget(target);
              if (closeOnPick) Navigator.pop(context);
            },
          ),
          const SizedBox(height: AppSpace.xs),
        ],
        const SizedBox(height: AppSpace.xs),
        AppButton(label: context.l10n.ok, onPressed: () => Navigator.pop(context)),
      ],
    );
  }
}
