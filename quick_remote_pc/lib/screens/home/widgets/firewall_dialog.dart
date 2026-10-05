import 'package:flutter/material.dart';
import '../../../l10n/app_language.dart';
import '../../../widgets/ui/ui.dart';

/// Explains that the firewall blocks phones; true when the user wants the
/// ports opened.
Future<bool?> showFirewallDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) {
      final p = ctx.palette;
      return AlertDialog(
        // A short window scrolls the content instead of cutting it off.
        scrollable: true,
        icon: Center(child: IconBadge(icon: Icons.security_rounded, color: p.warning, size: 56)),
        title: Text(
          context.l10n.firewallDialogTitle,
          textAlign: TextAlign.center,
          style: AppType.title.copyWith(color: p.textPrimary, fontSize: 20),
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Text(
            context.l10n.firewallDialogContent,
            style: AppType.body.copyWith(color: p.textSecondary, fontSize: 14, height: 1.5),
          ),
        ),
        actions: [
          AppButton(
            label: context.l10n.later,
            variant: AppButtonVariant.ghost,
            tone: AppTone.neutral,
            expand: false,
            height: 44,
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          AppButton(
            label: context.l10n.openPortsButton,
            icon: Icons.lock_open_rounded,
            variant: AppButtonVariant.solid,
            tone: AppTone.warning,
            expand: false,
            height: 44,
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      );
    },
  );
}
