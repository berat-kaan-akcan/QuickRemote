import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'app_popup_theme.dart';

/// Ortak bottom sheet wrapper.
/// Tüm bottom sheet'ler bu fonksiyon üzerinden açılarak
/// glassmorphism, handle bar ve klavye uyumu standartlaştırılır.
class AppBottomSheet {
  AppBottomSheet._();

  /// Standart glassmorphism bottom sheet açar.
  ///
  /// [builder] — bottom sheet içeriğini oluşturan fonksiyon.
  /// İçerik otomatik olarak blur, handle bar, yarı-saydam arkaplan ve
  /// klavye boşluğu (viewInsets.bottom) ile sarılır.
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget Function(BuildContext context) builder,
    bool isDismissible = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: isDismissible,
      builder: (ctx) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppPopupTheme.bottomSheetRadius),
          ),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(
              sigmaX: AppPopupTheme.blurSigma,
              sigmaY: AppPopupTheme.blurSigma,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: AppPopupTheme.bottomSheetBg.withValues(
                  alpha: AppPopupTheme.bottomSheetBgAlpha,
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppPopupTheme.bottomSheetRadius),
                ),
                border: Border(
                  top: BorderSide(
                    color: Colors.white.withValues(
                      alpha: AppPopupTheme.borderAlpha,
                    ),
                    width: 1,
                  ),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  24,
                  16,
                  24,
                  MediaQuery.of(ctx).viewInsets.bottom + 24,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle bar
                    Container(
                      width: AppPopupTheme.handleWidth,
                      height: AppPopupTheme.handleHeight,
                      decoration: BoxDecoration(
                        color: AppPopupTheme.handleColor,
                        borderRadius: BorderRadius.circular(
                          AppPopupTheme.handleRadius,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // İçerik
                    builder(ctx),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Bottom sheet başlığı oluşturur (ikon + metin).
  static Widget buildTitle(String title, {IconData? icon}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, color: Colors.white.withValues(alpha: 0.9), size: 20),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  /// Bottom sheet'te kullanılan standart "İptal" butonu.
  static Widget buildCancelButton(BuildContext context, {String text = 'İptal'}) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: TextButton(
        onPressed: () => Navigator.pop(context),
        style: TextButton.styleFrom(
          backgroundColor: Colors.white.withValues(alpha: 0.08),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
