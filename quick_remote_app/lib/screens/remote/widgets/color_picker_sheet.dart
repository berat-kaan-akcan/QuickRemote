import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quick_remote_shared/quick_remote_shared.dart';
import '../../../models/draw_tool.dart';
import '../../../l10n/app_language.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/ui/app_bottom_sheet.dart';
import '../../../widgets/ui/ui.dart';

class ColorPickerSheet {
  static void show(BuildContext context, DrawTool tool, void Function(String) onSend) {
    AppBottomSheet.show<void>(
      context: context,
      builder: (context) {
        final colors = [
          (context.l10n.colorRed, AppColors.inkRed, 255),
          (context.l10n.colorBlue, AppColors.inkBlue, 16711680),
          (context.l10n.colorGreen, AppColors.inkGreen, 65280),
          (context.l10n.colorYellow, AppColors.inkYellow, 65535),
          (context.l10n.colorWhite, AppColors.inkWhite, 16777215),
          (context.l10n.colorPurple, AppColors.inkPurple, 8388736),
        ];
        final p = context.palette;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBottomSheet.buildTitle(
              tool == DrawTool.pen ? context.l10n.penColorTitle : context.l10n.highlighterColorTitle,
              icon: tool == DrawTool.pen ? Icons.edit_rounded : Icons.border_color_rounded,
            ),
            const SizedBox(height: AppSpace.xl),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: AppSpace.md,
              crossAxisSpacing: AppSpace.md,
              childAspectRatio: 1.05,
              children: [
                for (final (i, (name, color, bgr)) in colors.indexed)
                  FadeSlideIn(
                    index: i,
                    child: Pressable(
                      semanticLabel: name,
                      pressedScale: 0.9,
                      borderRadius: AppRadius.all(AppRadius.lg),
                      onTap: () {
                        HapticFeedback.lightImpact();
                        // Pen and highlighter keep separate colors.
                        onSend(tool == DrawTool.pen
                            ? RemoteCommands.penColor(bgr)
                            : RemoteCommands.highlighterColor(bgr));
                        Navigator.pop(context);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: p.surfaceSunken,
                          borderRadius: AppRadius.all(AppRadius.lg),
                          border: Border.all(color: p.border),
                        ),
                        child: ExcludeSemantics(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: p.borderStrong, width: 1.5),
                                  boxShadow: [
                                    BoxShadow(color: color.withValues(alpha: 0.45), blurRadius: 14, spreadRadius: -2),
                                  ],
                                ),
                              ),
                              const SizedBox(height: AppSpace.xs),
                              Text(
                                name,
                                style: AppType.labelSmall.copyWith(color: p.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpace.xl),
            AppButton(
              label: context.l10n.cancel,
              variant: AppButtonVariant.outline,
              tone: AppTone.neutral,
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }
}
