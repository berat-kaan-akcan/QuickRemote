import 'package:flutter/material.dart';

import '../../l10n/app_language.dart';
import '../../widgets/ui/ui.dart';
import 'app_popup_theme.dart';

/// Ortak dialog wrapper fonksiyonları.
/// Onay, uyarı ve bilgi dialogları için standart yapı sağlar.
class AppDialog {
  AppDialog._();

  /// Onay dialogu gösterir (sil, kes vb. tehlikeli aksiyonlar).
  ///
  /// Dönen değer: kullanıcı onayladıysa `true`, iptal ettiyse `false`.
  static Future<bool> showConfirm({
    required BuildContext context,
    required String title,
    required String content,
    required String confirmText,
    AppTone tone = AppTone.danger,
    String? cancelText,
    IconData? icon,
    AppTone? iconTone,
    bool barrierDismissible = true,
  }) async {
    final result = await AppPopupTheme.showAppDialog<bool>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (ctx) => AppDialogFrame(
        icon: icon,
        iconTone: iconTone ?? tone,
        title: title,
        content: Text(content, textAlign: TextAlign.center),
        actions: [
          AppButton(
            label: confirmText,
            variant: AppButtonVariant.solid,
            tone: tone,
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
          AppButton(
            label: cancelText ?? context.l10n.cancel,
            variant: AppButtonVariant.ghost,
            tone: AppTone.neutral,
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  /// Bilgi dialogu gösterir (salt okunur içerik).
  static Future<void> showInfo({
    required BuildContext context,
    required String title,
    required Widget content,
    String? closeText,
    IconData? icon,
    AppTone iconTone = AppTone.primary,
  }) {
    return AppPopupTheme.showAppDialog<void>(
      context: context,
      builder: (ctx) => AppDialogFrame(
        icon: icon,
        iconTone: iconTone,
        title: title,
        alignStart: true,
        content: content,
        actions: [
          AppButton(
            label: closeText ?? context.l10n.close,
            variant: AppButtonVariant.tonal,
            onPressed: () => Navigator.pop(ctx),
          ),
        ],
      ),
    );
  }
}

/// The body of every dialog: an icon badge, a title, the content and full
/// width actions stacked under it (long labels never get cut).
class AppDialogFrame extends StatelessWidget {
  const AppDialogFrame({
    super.key,
    required this.title,
    required this.content,
    required this.actions,
    this.icon,
    this.iconTone = AppTone.primary,
    this.alignStart = false,
  });

  final String title;
  final Widget content;
  final List<Widget> actions;
  final IconData? icon;
  final AppTone iconTone;

  /// Left-aligns the title and content, for longer text.
  final bool alignStart;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final cross = alignStart ? CrossAxisAlignment.start : CrossAxisAlignment.center;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: AppSpace.xl, vertical: AppSpace.xl),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppPopupTheme.maxWidth),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpace.xl, AppSpace.xl, AppSpace.xl, AppSpace.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: cross,
            children: [
              if (icon != null) ...[
                IconBadge(icon: icon!, color: p.tone(iconTone), size: 56),
                const SizedBox(height: AppSpace.md),
              ],
              Text(
                title,
                textAlign: alignStart ? TextAlign.start : TextAlign.center,
                style: AppType.title.copyWith(color: p.textPrimary, fontSize: 20),
              ),
              const SizedBox(height: AppSpace.sm),
              Flexible(
                child: DefaultTextStyle.merge(
                  style: AppType.body.copyWith(color: p.textSecondary),
                  textAlign: alignStart ? TextAlign.start : TextAlign.center,
                  child: content,
                ),
              ),
              const SizedBox(height: AppSpace.xl),
              for (final (i, action) in actions.indexed) ...[
                if (i > 0) const SizedBox(height: AppSpace.xs),
                action,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
