import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../utils/ui/app_dialog.dart';
import '../../../utils/ui/app_popup_theme.dart';
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
      iconTone: AppTone.danger,
      actionsInRow: true,
    );
    if (result) HapticFeedback.mediumImpact();
    return result;
  }

  /// The whole note of slide [slide]; a long one scrolls.
  static void showNotesDialog(BuildContext context, String notes, int slide) {
    AppPopupTheme.showAppDialog<void>(
      context: context,
      builder: (ctx) {
        final p = ctx.palette;
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: AppSpace.xl),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppPopupTheme.maxWidth),
            child: Padding(
              padding: const EdgeInsets.all(AppSpace.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      IconBadge(icon: Icons.notes_rounded, color: p.primaryText, size: 38),
                      const SizedBox(width: AppSpace.sm),
                      Expanded(
                        child: Text(
                          ctx.l10n.notesTitle,
                          style: AppType.title.copyWith(color: p.textPrimary, fontSize: 19),
                        ),
                      ),
                      if (slide > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: p.surface,
                            borderRadius: AppRadius.all(AppRadius.pill),
                            border: Border.all(color: p.border),
                          ),
                          child: Text(
                            ctx.l10n.notesSlide(slide),
                            style: AppType.labelSmall.copyWith(color: p.textPrimary, fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.md),
                  Flexible(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Text(
                        notes.isEmpty ? ctx.l10n.notesEmpty : notes,
                        style: AppType.body.copyWith(
                          color: notes.isEmpty ? p.textMuted : p.textPrimary,
                          fontSize: 16,
                          height: 1.55,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpace.lg),
                  AppButton(label: ctx.l10n.ok, onPressed: () => Navigator.pop(ctx)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
