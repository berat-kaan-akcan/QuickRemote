import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/draw_tool.dart';
import '../../../l10n/app_language.dart';
import '../../../widgets/ui/ui.dart';
import 'touchpad_surface.dart';

/// The drawing tools and Clear under the touchpad. The selected tool is lit
/// in its color; the pen and highlighter wear a dot of their ink.
class DrawToolBar extends StatelessWidget {
  final DrawTool activeTool;
  final ValueChanged<DrawTool> onToolSelected;
  final VoidCallback onClear;

  /// Called when the selected pen or highlighter is tapped again (or held):
  /// its colors. Null: the tools have no colors.
  final void Function(DrawTool)? onColorPickerRequested;

  /// Tools to show (all by default).
  final Set<DrawTool> tools;

  /// Label and icon of the laser tool where it is not a laser (e.g. "Cursor"
  /// when it only moves the mouse cursor); null: "Laser".
  final String? laserLabel;
  final IconData? laserIcon;

  /// The ink each tool was last given: the dot on its key.
  final Map<DrawTool, Color> inks;

  /// False fades every key and ignores taps (no slideshow runs).
  final bool enabled;

  const DrawToolBar({
    super.key,
    required this.activeTool,
    required this.onToolSelected,
    required this.onClear,
    this.onColorPickerRequested,
    this.tools = const {
      DrawTool.laser,
      DrawTool.pen,
      DrawTool.highlighter,
      DrawTool.eraser,
    },
    this.laserLabel,
    this.laserIcon,
    this.inks = const {},
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final shown = DrawTool.values.where(tools.contains);
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: AppRadius.all(AppRadius.lg),
        border: Border.all(color: p.border),
      ),
      child: Row(
        children: [
          for (final tool in shown) ...[
            _buildToolButton(context, tool),
            const SizedBox(width: AppSpace.xxs),
          ],
          _buildClearButton(context),
        ],
      ),
    );
  }

  String _label(BuildContext context, DrawTool tool) => switch (tool) {
    DrawTool.laser => laserLabel ?? context.l10n.toolLaser,
    DrawTool.pen => context.l10n.toolPen,
    DrawTool.highlighter => context.l10n.toolHighlight,
    DrawTool.eraser => context.l10n.toolEraser,
  };

  Widget _buildToolButton(BuildContext context, DrawTool tool) {
    final p = context.palette;
    final label = _label(context, tool);
    final isActive = activeTool == tool;
    final hasColors = tool == DrawTool.pen || tool == DrawTool.highlighter;
    final canPickColor = hasColors && onColorPickerRequested != null;
    final activeColor = tool.colorIn(p);
    final ink = hasColors ? inks[tool] : null;

    return Expanded(
      child: Pressable(
        semanticLabel: label,
        selected: isActive,
        tooltip: context.l10n.selectTool(label),
        pressedScale: 0.92,
        dimWhenDisabled: false,
        borderRadius: AppRadius.all(AppRadius.md),
        onTap: !enabled
            ? null
            : () {
                HapticFeedback.lightImpact();
                if (isActive && canPickColor) {
                  onColorPickerRequested!(tool);
                } else {
                  onToolSelected(tool);
                }
              },
        onLongPress: enabled && canPickColor
            ? () {
                HapticFeedback.mediumImpact();
                onColorPickerRequested!(tool);
              }
            : null,
        child: _ToolKey(
          icon: tool == DrawTool.laser ? laserIcon ?? tool.icon : tool.icon,
          label: label,
          color: isActive && enabled ? activeColor : p.textSecondary,
          active: isActive && enabled,
          ink: ink,
          enabled: enabled,
        ),
      ),
    );
  }

  Widget _buildClearButton(BuildContext context) {
    final p = context.palette;
    return Expanded(
      child: Pressable(
        semanticLabel: context.l10n.clearInk,
        tooltip: context.l10n.clearInkTooltip,
        pressedScale: 0.92,
        dimWhenDisabled: false,
        borderRadius: AppRadius.all(AppRadius.md),
        onTap: !enabled
            ? null
            : () {
                HapticFeedback.mediumImpact();
                onClear();
              },
        child: _ToolKey(
          icon: Icons.cleaning_services_rounded,
          label: context.l10n.clearInk,
          color: p.textSecondary,
          active: false,
          enabled: enabled,
        ),
      ),
    );
  }
}

class _ToolKey extends StatelessWidget {
  const _ToolKey({
    required this.icon,
    required this.label,
    required this.color,
    required this.active,
    required this.enabled,
    this.ink,
  });

  final IconData icon;
  final String label;
  final Color color;
  final bool active;
  final bool enabled;
  final Color? ink;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final radius = AppRadius.all(AppRadius.md);
    return AnimatedOpacity(
      duration: AppMotion.of(context, AppMotion.base),
      opacity: enabled ? 1 : 0.3,
      child: AnimatedContainer(
        duration: AppMotion.of(context, AppMotion.base),
        curve: AppMotion.standard,
        height: 56,
        decoration: BoxDecoration(
          color: active
              ? color.withValues(alpha: 0.17)
              : color.withValues(alpha: 0),
          borderRadius: radius,
          border: Border.all(
            color: active ? color : color.withValues(alpha: 0),
            width: 1.5,
          ),
        ),
        child: ExcludeSemantics(
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 22, color: color),
                    const SizedBox(height: 2),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          label,
                          maxLines: 1,
                          style: AppType.labelSmall.copyWith(
                            color: color,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (ink != null)
                Positioned(
                  top: 6,
                  right: 8,
                  child: Container(
                    width: 11,
                    height: 11,
                    decoration: BoxDecoration(
                      color: ink,
                      shape: BoxShape.circle,
                      border: Border.all(color: p.surface, width: 2),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
