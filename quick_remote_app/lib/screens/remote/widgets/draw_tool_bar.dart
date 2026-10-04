import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/draw_tool.dart';
import '../../../l10n/app_language.dart';
import '../../../widgets/ui/ui.dart';
import 'touchpad_surface.dart';

class DrawToolBar extends StatelessWidget {
  final DrawTool activeTool;
  final ValueChanged<DrawTool> onToolSelected;
  final VoidCallback onClear;

  /// Eğer null değilse Kalem ve Vurgulayıcı araçlarında renk seçici ikonu gösterilir
  /// ve mevcut araç seçiliyken tekrar tıklanırsa veya uzun basılırsa bu callback çağrılır.
  final void Function(DrawTool)? onColorPickerRequested;

  /// Tools to show (all by default).
  final Set<DrawTool> tools;

  /// Label of the laser tool (e.g. "Cursor" when it only moves the mouse
  /// cursor); null: "Laser".
  final String? laserLabel;

  const DrawToolBar({
    super.key,
    required this.activeTool,
    required this.onToolSelected,
    required this.onClear,
    this.onColorPickerRequested,
    this.tools = const {DrawTool.laser, DrawTool.pen, DrawTool.highlighter, DrawTool.eraser},
    this.laserLabel,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.all(AppSpace.xxs),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: AppRadius.all(AppRadius.lg),
        border: Border.all(color: p.border),
      ),
      child: Row(
        children: [
          if (tools.contains(DrawTool.laser))
            _buildToolButton(
              context,
              tool: DrawTool.laser,
              label: laserLabel ?? context.l10n.toolLaser,
            ),
          if (tools.contains(DrawTool.pen))
            _buildToolButton(
              context,
              tool: DrawTool.pen,
              label: context.l10n.toolPen,
              supportsColorPicker: true,
            ),
          if (tools.contains(DrawTool.highlighter))
            _buildToolButton(
              context,
              tool: DrawTool.highlighter,
              label: context.l10n.toolHighlight,
              supportsColorPicker: true,
            ),
          if (tools.contains(DrawTool.eraser))
            _buildToolButton(
              context,
              tool: DrawTool.eraser,
              label: context.l10n.toolEraser,
            ),
          Container(
            width: 1,
            height: 34,
            margin: const EdgeInsets.symmetric(horizontal: AppSpace.xxs),
            color: p.border,
          ),
          _buildClearButton(context),
        ],
      ),
    );
  }

  Widget _buildToolButton(BuildContext context, {
    required DrawTool tool,
    required String label,
    bool supportsColorPicker = false,
  }) {
    final p = context.palette;
    final isActive = activeTool == tool;
    final canPickColor = supportsColorPicker && onColorPickerRequested != null;
    final activeColor = tool.colorIn(p);
    final color = isActive ? activeColor : p.textMuted;

    return Expanded(
      child: Pressable(
        semanticLabel: label,
        selected: isActive,
        tooltip: context.l10n.selectTool(label),
        pressedScale: 0.92,
        borderRadius: AppRadius.all(AppRadius.md),
        onTap: () {
          HapticFeedback.lightImpact();
          if (isActive && canPickColor) {
            onColorPickerRequested!(tool);
          } else {
            onToolSelected(tool);
          }
        },
        onLongPress: canPickColor
            ? () {
                HapticFeedback.mediumImpact();
                onColorPickerRequested!(tool);
              }
            : null,
        child: AnimatedContainer(
          duration: AppMotion.of(context, AppMotion.base),
          curve: AppMotion.standard,
          height: 54,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: isActive ? activeColor.withValues(alpha: p.isDark ? 0.16 : 0.11) : null,
            borderRadius: AppRadius.all(AppRadius.md),
            border: Border.all(
              color: isActive ? activeColor.withValues(alpha: 0.5) : activeColor.withValues(alpha: 0),
            ),
          ),
          child: ExcludeSemantics(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(tool.icon, size: 20, color: color),
                    if (canPickColor)
                      Icon(Icons.arrow_drop_down_rounded, size: 16, color: color.withValues(alpha: 0.8)),
                  ],
                ),
                const SizedBox(height: 3),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      maxLines: 1,
                      style: AppType.labelSmall.copyWith(
                        color: color,
                        fontSize: 11.5,
                        fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildClearButton(BuildContext context) {
    final p = context.palette;
    return SizedBox(
      width: 60,
      child: Pressable(
        semanticLabel: context.l10n.clearInk,
        tooltip: context.l10n.clearInkTooltip,
        pressedScale: 0.92,
        borderRadius: AppRadius.all(AppRadius.md),
        onTap: () {
          HapticFeedback.mediumImpact();
          onClear();
        },
        child: SizedBox(
          height: 54,
          child: ExcludeSemantics(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cleaning_services_rounded, size: 20, color: p.textSecondary),
                const SizedBox(height: 3),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    context.l10n.clearInk,
                    maxLines: 1,
                    style: AppType.labelSmall.copyWith(color: p.textSecondary, fontSize: 11.5),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
