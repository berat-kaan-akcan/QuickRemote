import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../utils/ui/app_dialog.dart';
import '../../../utils/ui/app_popup_theme.dart';

class RemoteDialogs {
  static Future<bool> showExitDialog(BuildContext context) async {
    final result = await AppDialog.showConfirm(
      context: context,
      title: 'Bağlantıyı Kes',
      content: 'Bağlantıyı kesmek ve ana ekrana dönmek istediğinize emin misiniz?',
      confirmText: 'Bağlantıyı Kes',
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
      title: 'Slayt Notları',
      icon: Icons.notes_rounded,
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Text(
            notes.isEmpty ? 'Bu slayt için not bulunmuyor.' : notes,
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
