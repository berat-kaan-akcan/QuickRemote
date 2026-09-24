import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../utils/ui/app_bottom_sheet.dart';
import '../../../utils/ui/app_popup_theme.dart';
import '../../../utils/ui/app_snackbar.dart';

/// A8 ve A9'un birleştirilmiş hali.
/// Belirli bir slayttan sunum başlatmak için bottom sheet açar.
class SlidePickerSheet {
  SlidePickerSheet._();

  static Future<void> show(
    BuildContext context, {
    required int totalSlides,
    required void Function(String command) onSend,
  }) {
    final controller = TextEditingController();

    return AppBottomSheet.show(
      context: context,
      builder: (ctx) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBottomSheet.buildTitle('Sunuma Başla', icon: Icons.slideshow_rounded),
            const SizedBox(height: 24),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              autofocus: true,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: AppPopupTheme.inputDecoration(
                context: ctx,
                hintText: totalSlides > 0
                    ? 'Slayt (1-$totalSlides)'
                    : 'Slayt Numarası (Örn: 5)',
                helperText: totalSlides > 0
                    ? 'Maksimum $totalSlides slayt girebilirsiniz.'
                    : 'Boş bırakırsanız baştan başlar.',
              ),
              onSubmitted: (value) {
                _handleSubmit(ctx, value, totalSlides, onSend);
              },
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.08),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'İptal',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: FilledButton(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        _handleSubmit(ctx, controller.text, totalSlides, onSend);
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppPopupTheme.successColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppPopupTheme.buttonRadius),
                        ),
                      ),
                      child: const Text(
                        'Başlat',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  static void _handleSubmit(
    BuildContext context,
    String value,
    int totalSlides,
    void Function(String command) onSend,
  ) {
    final slideNumber = value.trim();
    if (slideNumber.isNotEmpty) {
      final parsed = int.tryParse(slideNumber);
      final maxSlide = totalSlides > 0 ? totalSlides : 9999;
      if (parsed == null || parsed <= 0 || parsed > maxSlide) {
        AppSnackbar.show(
          context,
          message: 'Geçerli bir slayt numarası girin (1-$maxSlide)',
          type: SnackbarType.error,
        );
        return;
      }
      onSend('START_AT:$parsed');
    } else {
      onSend('START');
    }
    Navigator.pop(context);
  }
}
