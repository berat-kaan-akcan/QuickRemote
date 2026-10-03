import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../utils/ui/app_dialog.dart';
import '../../../utils/ui/app_popup_theme.dart';
import '../../../l10n/app_language.dart';

class RemoteDialogs {
  static Future<bool> showExitDialog(BuildContext context) async {
    final result = await AppDialog.showConfirm(
      context: context,
      title: context.l10n.disconnectTitle,
      content: context.l10n.disconnectContent,
      confirmText: context.l10n.disconnectTitle,
      confirmColor: AppPopupTheme.dangerColor,
      icon: Icons.warning_amber_rounded,
      iconColor: const Color(0xFFFFB74D),
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
            style: TextStyle(
              color: notes.isEmpty ? Colors.white54 : Colors.white,
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}
