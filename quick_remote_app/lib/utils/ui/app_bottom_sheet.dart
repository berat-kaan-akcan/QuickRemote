import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../l10n/app_language.dart';
import '../../widgets/ui/ui.dart';
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
      constraints: const BoxConstraints(maxWidth: AppSpace.contentMaxWidth),
      sheetAnimationStyle: AppMotion.reduced(context)
          ? AnimationStyle.noAnimation
          : AnimationStyle(duration: AppMotion.slow, reverseDuration: AppMotion.base),
      builder: (ctx) => SheetFrame(child: builder(ctx)),
    );
  }

  /// Bottom sheet başlığı oluşturur (ikon + metin).
  static Widget buildTitle(String title, {IconData? icon}) {
    return Builder(
      builder: (context) {
        final p = context.palette;
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              IconBadge(icon: icon, color: p.primaryText, size: 38),
              const SizedBox(width: AppSpace.sm),
            ],
            Flexible(
              child: Text(
                title,
                style: AppType.title.copyWith(color: p.textPrimary, fontSize: 20),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        );
      },
    );
  }

  /// Bottom sheet'te kullanılan standart "İptal" butonu.
  static Widget buildCancelButton(BuildContext context, {String? text}) {
    return AppButton(
      label: text ?? context.l10n.cancel,
      variant: AppButtonVariant.outline,
      tone: AppTone.neutral,
      onPressed: () => Navigator.pop(context),
    );
  }
}

/// The frosted panel, handle and insets of every bottom sheet.
class SheetFrame extends StatelessWidget {
  const SheetFrame({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    const radius = BorderRadius.vertical(top: Radius.circular(AppPopupTheme.bottomSheetRadius));
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: p.surfaceRaised.withValues(alpha: p.isDark ? 0.9 : 0.94),
            borderRadius: radius,
            border: Border(top: BorderSide(color: p.glassBorder)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpace.xl,
                AppSpace.sm,
                AppSpace.xl,
                MediaQuery.viewInsetsOf(context).bottom + AppSpace.lg,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: AppPopupTheme.handleWidth,
                    height: AppPopupTheme.handleHeight,
                    decoration: BoxDecoration(
                      color: p.borderStrong,
                      borderRadius: AppRadius.all(AppRadius.pill),
                    ),
                  ),
                  const SizedBox(height: AppSpace.lg),
                  Flexible(child: child),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
