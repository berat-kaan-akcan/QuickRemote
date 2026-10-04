import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../providers/settings_provider.dart';
import '../../../utils/ui/app_bottom_sheet.dart';
import '../../../utils/ui/app_popup_theme.dart';
import '../../../utils/ui/app_snackbar.dart';
import '../../../l10n/app_language.dart';

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
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: AppPopupTheme.inputDecoration(
                  context: context,
                  hintText: context.l10n.enterTime,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _TypeChip(
                      label: context.l10n.unitSecondsLong,
                      isSelected: !isMinutes,
                      onTap: () => setState(() => isMinutes = false),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _TypeChip(
                      label: context.l10n.unitMinutesLong,
                      isSelected: isMinutes,
                      onTap: () => setState(() => isMinutes = true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.08),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          context.l10n.cancel,
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
                        style: FilledButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppPopupTheme.buttonRadius),
                          ),
                        ),
                        child: Text(context.l10n.add, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
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
    },
  );
}

class _TypeChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeChip({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected 
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.05),
          border: Border.all(
            color: isSelected 
                ? Theme.of(context).colorScheme.primary
                : Colors.transparent,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Theme.of(context).colorScheme.primary : Colors.white70,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
