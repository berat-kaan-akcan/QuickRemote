import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/draw_tool.dart';
import '../../../l10n/app_language.dart';

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
    return Row(
      children: [
        if (tools.contains(DrawTool.laser)) ...[
          _buildToolButton(
            context,
            tool: DrawTool.laser,
            icon: Icons.highlight_rounded,
            label: laserLabel ?? context.l10n.toolLaser,
            activeColor: const Color(0xFFFF1744),
          ),
          const SizedBox(width: 4),
        ],
        if (tools.contains(DrawTool.pen)) ...[
          _buildToolButton(
            context,
            tool: DrawTool.pen,
            icon: Icons.edit_rounded,
            label: context.l10n.toolPen,
            activeColor: const Color(0xFF00E676),
            supportsColorPicker: true,
          ),
          const SizedBox(width: 4),
        ],
        if (tools.contains(DrawTool.highlighter)) ...[
          _buildToolButton(
            context,
            tool: DrawTool.highlighter,
            icon: Icons.border_color_rounded,
            label: context.l10n.toolHighlight,
            activeColor: const Color(0xFFFFEA00),
            supportsColorPicker: true,
          ),
          const SizedBox(width: 4),
        ],
        if (tools.contains(DrawTool.eraser)) ...[
          _buildToolButton(
            context,
            tool: DrawTool.eraser,
            icon: Icons.auto_fix_high_rounded,
            label: context.l10n.toolEraser,
            activeColor: const Color(0xFFFF9800),
          ),
          const SizedBox(width: 4),
        ],
        _buildClearButton(context),
      ],
    );
  }

  Widget _buildToolButton(BuildContext context, {
    required DrawTool tool,
    required IconData icon,
    required String label,
    required Color activeColor,
    bool supportsColorPicker = false,
  }) {
    final isActive = activeTool == tool;
    final canPickColor = supportsColorPicker && onColorPickerRequested != null;

    return Expanded(
      child: Semantics(
        button: true,
        label: label,
        child: Tooltip(
          message: context.l10n.selectTool(label),
          child: GestureDetector(
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
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.symmetric(
                vertical: 10,
                horizontal: canPickColor ? 2 : 4,
              ),
              decoration: BoxDecoration(
                color: isActive
                    ? activeColor.withValues(alpha: 0.2)
                    : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isActive
                      ? activeColor.withValues(alpha: 0.5)
                      : Colors.transparent,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 14,
                    color: isActive ? activeColor : Colors.white38,
                  ),
                  const SizedBox(width: 2),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        label,
                        style: TextStyle(
                          color: isActive ? activeColor : Colors.white38,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  if (canPickColor)
                    Icon(
                      Icons.arrow_drop_down_rounded,
                      size: 16,
                      color: isActive ? activeColor : Colors.white54,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildClearButton(BuildContext context) {
    return Expanded(
      child: Semantics(
        button: true,
        label: context.l10n.clearInk,
        child: Tooltip(
          message: context.l10n.clearInkTooltip,
          child: GestureDetector(
            onTap: () {
              HapticFeedback.mediumImpact();
              onClear();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(
                vertical: 10,
                horizontal: 2,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.transparent,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.cleaning_services_rounded,
                    size: 14,
                    color: Colors.white38,
                  ),
                  const SizedBox(width: 2),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        context.l10n.clearInk,
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
