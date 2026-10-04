import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../utils/ui/app_dialog.dart';
import '../../../l10n/app_language.dart';
import '../../../widgets/ui/ui.dart';

class RemoteDialogs {
  static Future<bool> showExitDialog(BuildContext context) async {
    final result = await AppDialog.showConfirm(
      context: context,
      title: context.l10n.disconnectTitle,
      content: context.l10n.disconnectContent,
      confirmText: context.l10n.disconnectTitle,
      tone: AppTone.danger,
      icon: Icons.link_off_rounded,
      iconTone: AppTone.warning,
    );
    if (result) HapticFeedback.mediumImpact();
    return result;
  }

  static void showNotesDialog(BuildContext context, String notes) {
    AppDialog.showInfo(
      context: context,
      title: context.l10n.notesTitle,
      icon: Icons.notes_rounded,
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Text(
            notes.isEmpty ? context.l10n.notesEmpty : notes,
            style: AppType.body.copyWith(
              color: notes.isEmpty ? context.palette.textMuted : context.palette.textPrimary,
              fontSize: 16,
              height: 1.55,
            ),
          ),
        ),
      ),
    );
  }
}
