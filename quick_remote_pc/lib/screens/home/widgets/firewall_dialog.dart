import 'package:flutter/material.dart';
import '../../../l10n/app_language.dart';
import '../../../theme/app_colors.dart';

/// Explains that the firewall blocks phones; true when the user wants the
/// ports opened.
Future<bool?> showFirewallDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      icon: const Icon(
        Icons.security_rounded,
        color: AppColors.warning,
        size: 48,
      ),
      title: Text(
        context.l10n.firewallDialogTitle,
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      content: Text(
        context.l10n.firewallDialogContent,
        style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(
            context.l10n.later,
            style: TextStyle(color: Colors.white54),
          ),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.warning,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            context.l10n.openPortsButton,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}
