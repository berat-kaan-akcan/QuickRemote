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
          final p = context.palette;
          Widget unit(String label, bool minutes) {
            final on = isMinutes == minutes;
            return Expanded(
              child: Pressable(
                onTap: () => setState(() => isMinutes = minutes),
                selected: on,
                semanticLabel: label,
                pressedScale: 0.97,
                borderRadius: AppRadius.all(AppRadius.sm),
                child: AnimatedContainer(
                  duration: AppMotion.of(context, AppMotion.base),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: on ? p.surfaceRaised : p.surfaceRaised.withValues(alpha: 0),
                    borderRadius: AppRadius.all(AppRadius.sm),
                    boxShadow: on ? AppShadows.soft(p) : null,
                  ),
                  child: Text(
                    label,
                    style: AppType.labelSmall.copyWith(color: on ? p.textPrimary : p.textSecondary, fontSize: 12.5),
                  ),
                ),
              ),
            );
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppBottomSheet.buildHeader(context.l10n.newWarningTime, icon: Icons.timer_outlined, iconColor: p.warning),
              const SizedBox(height: AppSpace.md),
              SizedBox(
                height: 58,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller,
                        autofocus: true,
                        style: AppType.numeric.copyWith(color: p.textPrimary, fontSize: 22, letterSpacing: 0),
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: AppPopupTheme.inputDecoration(
                          context: context,
                          hintText: context.l10n.enterTime,
                        ).copyWith(hintStyle: AppType.body.copyWith(color: p.textMuted)),
                      ),
                    ),
                    const SizedBox(width: AppSpace.sm),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(color: p.surfaceSunken, borderRadius: AppRadius.all(AppRadius.md)),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            unit(context.l10n.unitMinutesLong, true),
                            const SizedBox(width: 3),
                            unit(context.l10n.unitSecondsLong, false),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpace.md),
              Row(
                children: [
                  Expanded(
                    flex: 10,
                    child: AppButton(
                      label: context.l10n.cancel,
                      variant: AppButtonVariant.outline,
                      tone: AppTone.neutral,
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ),
                  const SizedBox(width: AppSpace.sm),
                  Expanded(
                    flex: 13,
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
