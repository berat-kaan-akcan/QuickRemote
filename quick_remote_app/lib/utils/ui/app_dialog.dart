import 'package:flutter/material.dart';
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
    Color confirmColor = AppPopupTheme.dangerColor,
    String cancelText = 'İptal',
    IconData? icon,
    Color? iconColor,
    bool barrierDismissible = true,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppPopupTheme.dialogBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppPopupTheme.dialogRadius),
        ),
        icon: icon != null
            ? Icon(icon, color: iconColor ?? confirmColor, size: 48)
            : null,
        title: Text(
          title,
          style: const TextStyle(
            color: AppPopupTheme.titleColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          content,
          style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              cancelText,
              style: const TextStyle(
                color: AppPopupTheme.cancelTextColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: confirmColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppPopupTheme.buttonRadius),
              ),
            ),
            child: Text(
              confirmText,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
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
    String closeText = 'Kapat',
    IconData? icon,
    Color? iconColor,
  }) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppPopupTheme.dialogBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppPopupTheme.dialogRadius),
        ),
        title: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: iconColor ?? AppPopupTheme.infoColor),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(
                title,
                style: const TextStyle(
                  color: AppPopupTheme.titleColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: content,
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            style: FilledButton.styleFrom(
              backgroundColor: AppPopupTheme.infoColor.withValues(alpha: 0.2),
              foregroundColor: AppPopupTheme.infoColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppPopupTheme.buttonRadius),
              ),
            ),
            child: Text(
              closeText,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
