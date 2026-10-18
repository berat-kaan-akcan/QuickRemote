import 'package:flutter/material.dart';
import 'ui/ui.dart';

enum StatusKind { success, warning, error }

/// Floating message on the raised surface with a colored edge and icon,
/// instead of Material's solid snackbar.
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
      // Just above the full-width Start/Stop key.
      margin: const EdgeInsets.fromLTRB(18, 0, 18, 78),
      content: Semantics(
        liveRegion: true,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: p.surfaceRaised,
            borderRadius: AppRadius.all(14),
            border: Border.all(color: color.withValues(alpha: 0.45)),
            boxShadow: AppShadows.raised(p),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: AppType.bodySmall.copyWith(color: p.textPrimary, fontSize: 13, fontWeight: FontWeight.w500, height: 1.35),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
