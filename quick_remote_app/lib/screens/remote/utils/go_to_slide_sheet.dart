import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quick_remote_shared/quick_remote_shared.dart';
import '../../../utils/ui/app_bottom_sheet.dart';
import '../../../utils/ui/app_popup_theme.dart';
import '../../../utils/ui/app_snackbar.dart';
import '../../../l10n/app_language.dart';
import '../../../widgets/ui/ui.dart';

/// "Go to slide": a slide number on the phone's own number keyboard. A
/// running show jumps there; otherwise the show starts from it.
class GoToSlideSheet {
  GoToSlideSheet._();

  static Future<void> show(
    BuildContext context, {
    required int totalSlides,
    required void Function(String command) onSend,
  }) {
    return AppBottomSheet.show(
      context: context,
      builder: (ctx) => _GoToSlide(totalSlides: totalSlides, onSend: onSend),
    );
  }
}

class _GoToSlide extends StatefulWidget {
  const _GoToSlide({required this.totalSlides, required this.onSend});

  final int totalSlides;
  final void Function(String command) onSend;

  @override
  State<_GoToSlide> createState() => _GoToSlideState();
}

class _GoToSlideState extends State<_GoToSlide> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final parsed = int.tryParse(_controller.text.trim());
    final maxSlide = widget.totalSlides > 0 ? widget.totalSlides : 9999;
    if (parsed == null || parsed <= 0 || parsed > maxSlide) {
      AppSnackbar.show(
        context,
        message: context.l10n.slidePickerInvalid(maxSlide),
        type: SnackbarType.error,
      );
      return;
    }
    HapticFeedback.mediumImpact();
    widget.onSend(RemoteCommands.startAt(parsed));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppBottomSheet.buildHeader(context.l10n.goToSlide, icon: Icons.grid_view_rounded),
        const SizedBox(height: AppSpace.sm),
        TextField(
          controller: _controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)],
          style: AppType.titleSmall.copyWith(color: p.textPrimary, fontSize: 20),
          decoration: AppPopupTheme.inputDecoration(context: context).copyWith(
            contentPadding: const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: AppSpace.md),
          ),
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) => _submit(),
        ),
        const SizedBox(height: AppSpace.xs),
        Text(
          widget.totalSlides > 0 ? context.l10n.goToSlideRange(widget.totalSlides) : context.l10n.goToSlideNumber,
          style: AppType.bodySmall.copyWith(color: p.textSecondary, fontSize: 12.5),
        ),
        const SizedBox(height: AppSpace.md),
        Row(
          children: [
            Expanded(
              flex: 5,
              child: AppButton(
                label: context.l10n.cancel,
                variant: AppButtonVariant.outline,
                tone: AppTone.neutral,
                onPressed: () => Navigator.pop(context),
              ),
            ),
            const SizedBox(width: AppSpace.sm),
            Expanded(
              flex: 7,
              child: AppButton(
                label: context.l10n.goAction,
                icon: Icons.arrow_forward_rounded,
                onPressed: _controller.text.trim().isEmpty ? null : _submit,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
