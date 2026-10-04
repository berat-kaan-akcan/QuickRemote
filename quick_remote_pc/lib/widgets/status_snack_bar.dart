import 'package:flutter/material.dart';
import 'ui/ui.dart';

enum StatusKind { success, warning, error }

/// Floating message styled like the status rows (tinted card, colored border,
/// icon and text) instead of Material's solid snackbar.
void showStatusSnackBar(
  BuildContext context,
  String message, {
  StatusKind kind = StatusKind.success,
  Duration duration = const Duration(seconds: 4),
}) {
  final p = context.palette;
  final (color, icon) = switch (kind) {
    StatusKind.success => (p.success, Icons.check_circle_rounded),
    StatusKind.warning => (p.warning, Icons.warning_amber_rounded),
    StatusKind.error => (p.danger, Icons.error_rounded),
  };
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      duration: duration,
      padding: EdgeInsets.zero,
      content: Semantics(
        liveRegion: true,
        child: Container(
          padding: const EdgeInsets.fromLTRB(AppSpace.sm, AppSpace.sm, AppSpace.md, AppSpace.sm),
          decoration: BoxDecoration(
            color: p.surfaceRaised,
            borderRadius: AppRadius.all(AppRadius.md),
            border: Border.all(color: color.withValues(alpha: 0.35)),
            boxShadow: AppShadows.raised(p),
          ),
          child: Row(
            children: [
              IconBadge(icon: icon, color: color, size: 32),
              const SizedBox(width: AppSpace.sm),
              Expanded(
                child: Text(
                  message,
                  style: AppType.bodySmall.copyWith(color: p.textPrimary, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
