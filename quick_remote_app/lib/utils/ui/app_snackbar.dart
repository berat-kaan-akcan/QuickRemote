import 'package:flutter/material.dart';
import 'app_popup_theme.dart';

enum SnackbarType { success, error, warning, info }

class AppSnackbar {
  static void show(
    BuildContext context, {
    required String message,
    SnackbarType type = SnackbarType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.hideCurrentSnackBar();

    Color bgColor;
    Color iconColor;
    IconData iconData;

    switch (type) {
      case SnackbarType.success:
        bgColor = AppPopupTheme.successColor.withValues(alpha: 0.15);
        iconColor = AppPopupTheme.successColor;
        iconData = Icons.check_circle_outline;
        break;
      case SnackbarType.error:
        bgColor = AppPopupTheme.dangerColor.withValues(alpha: 0.15);
        iconColor = AppPopupTheme.dangerColor;
        iconData = Icons.error_outline;
        break;
      case SnackbarType.warning:
        bgColor = AppPopupTheme.warningColor.withValues(alpha: 0.15);
        iconColor = AppPopupTheme.warningColor;
        iconData = Icons.warning_amber_rounded;
        break;
      case SnackbarType.info:
        bgColor = AppPopupTheme.infoColor.withValues(alpha: 0.15);
        iconColor = AppPopupTheme.infoColor;
        iconData = Icons.info_outline;
        break;
    }

    final snackBar = SnackBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.only(bottom: 24, left: 16, right: 16),
      duration: duration,
      content: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppPopupTheme.dialogBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: iconColor.withValues(alpha: 0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(iconData, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    scaffoldMessenger.showSnackBar(snackBar);
  }
}
