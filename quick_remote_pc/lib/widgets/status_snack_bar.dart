import 'package:flutter/material.dart';

enum StatusKind { success, warning, error }

/// Floating message styled like the status rows (tinted card, colored border,
/// icon and text) instead of Material's solid snackbar.
void showStatusSnackBar(
  BuildContext context,
  String message, {
  StatusKind kind = StatusKind.success,
  Duration duration = const Duration(seconds: 4),
}) {
  final (color, icon) = switch (kind) {
    StatusKind.success => (const Color(0xFF4CAF50), Icons.check_circle_rounded),
    StatusKind.warning => (const Color(0xFFFF9800), Icons.warning_amber_rounded),
    StatusKind.error => (const Color(0xFFFF5252), Icons.error_outline_rounded),
  };
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      duration: duration,
      padding: EdgeInsets.zero,
      content: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          // Opaque base so the page does not show through the tint.
          color: Color.alphaBlend(color.withValues(alpha: 0.12), const Color(0xFF0F172A)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
