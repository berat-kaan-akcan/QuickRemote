import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../providers/settings_provider.dart';
import '../../../utils/ui/app_bottom_sheet.dart';
import '../../../utils/ui/app_popup_theme.dart';
import '../../../utils/ui/app_snackbar.dart';
import '../../../l10n/app_language.dart';
import '../../../widgets/ui/ui.dart';

/// Asks for a new warning time in seconds or minutes.
void showAddWarningTimeSheet(BuildContext context) {
  AppBottomSheet.show(
    context: context,
    builder: (ctx) {
      final controller = TextEditingController();
      bool isMinutes = false;

      return StatefulBuilder(
        builder: (context, setState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBottomSheet.buildTitle(context.l10n.newWarningTime, icon: Icons.timer_rounded),
              const SizedBox(height: 24),
              TextField(
                controller: controller,
                autofocus: true,
                textAlign: TextAlign.center,
                style: AppType.numeric.copyWith(color: context.palette.textPrimary, fontSize: 32),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: AppPopupTheme.inputDecoration(
                  context: context,
                  hintText: context.l10n.enterTime,
                ).copyWith(
                  hintStyle: AppType.body.copyWith(color: context.palette.textMuted),
                  contentPadding: const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: AppSpace.lg),
                ),
              ),
              const SizedBox(height: AppSpace.md),
              AppSegmented<bool>(
                segments: [
                  AppSegment(value: false, label: context.l10n.unitSecondsLong),
                  AppSegment(value: true, label: context.l10n.unitMinutesLong),
                ],
                selected: isMinutes,
                onChanged: (value) => setState(() => isMinutes = value),
              ),
              const SizedBox(height: AppSpace.lg),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: context.l10n.cancel,
                      variant: AppButtonVariant.outline,
                      tone: AppTone.neutral,
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ),
                  const SizedBox(width: AppSpace.sm),
                  Expanded(
                    child: AppButton(
                      label: context.l10n.add,
                      icon: Icons.add_rounded,
                      onPressed: () {
                        final val = int.tryParse(controller.text);
                        if (val != null && val > 0) {
                          final seconds = isMinutes ? val * 60 : val;
                          context.read<SettingsProvider>().addWarningTime(seconds);
                          Navigator.of(ctx).pop();
                        } else {
                          AppSnackbar.show(
                            ctx,
                            message: context.l10n.enterValidNumber,
                            type: SnackbarType.error,
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          );
        },
      );
    },
  );
}
