import 'package:flutter/material.dart';

import '../../../models/draw_tool.dart';
import '../../../l10n/app_language.dart';
import '../../../theme/app_colors.dart';

extension DrawToolStyle on DrawTool {
  Color get color => switch (this) {
        DrawTool.laser => AppColors.laser,
        DrawTool.pen => AppColors.pen,
        DrawTool.highlighter => AppColors.highlighter,
        DrawTool.eraser => AppColors.warning,
      };

  IconData get icon => switch (this) {
        DrawTool.laser => Icons.highlight_rounded,
        DrawTool.pen => Icons.edit_rounded,
        DrawTool.highlighter => Icons.border_color_rounded,
        DrawTool.eraser => Icons.auto_fix_high_rounded,
      };
}

/// The touchpad's look, shared by the Wi-Fi and Bluetooth remotes: a quiet
/// panel with a hint, lit in the tool's color while a finger is down.
class TouchpadSurface extends StatelessWidget {
  const TouchpadSurface({
    super.key,
    required this.isDrawActive,
    required this.activeTool,
    this.laserLabel,
  });

  final bool isDrawActive;
  final DrawTool activeTool;

  /// Replaces "Laser" where the laser is just the mouse cursor.
  final String? laserLabel;

  String _label(BuildContext context, DrawTool tool) => switch (tool) {
        DrawTool.laser => laserLabel ?? context.l10n.toolLaser,
        DrawTool.pen => context.l10n.toolPen,
        DrawTool.highlighter => context.l10n.toolHighlighter,
        DrawTool.eraser => context.l10n.toolEraser,
      };

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final toolColor = activeTool.color;
    final hintStyle = TextStyle(color: Colors.white.withValues(alpha: 0.15), fontSize: 12, fontWeight: FontWeight.w500);

    return Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(
          child: _panel(
            border: Border.all(color: primary.withValues(alpha: 0.2), width: 2),
            shadow: primary.withValues(alpha: 0.05),
          ),
        ),
        // Fades in instead of animating the border, so a touch repaints
        // only this layer.
        AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: isDrawActive ? 1.0 : 0.0,
          child: RepaintBoundary(
            child: _panel(
              border: Border.all(color: toolColor, width: 2.5),
              shadow: toolColor.withValues(alpha: 0.15),
            ),
          ),
        ),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: isDrawActive
                ? [
                    Icon(activeTool.icon, color: toolColor.withValues(alpha: 0.3), size: 48),
                    const SizedBox(height: 8),
                    Text(
                      _label(context, activeTool),
                      style: TextStyle(
                        color: toolColor.withValues(alpha: 0.4),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ]
                : [
                    Icon(Icons.touch_app_rounded, color: Colors.white.withValues(alpha: 0.08), size: 48),
                    const SizedBox(height: 12),
                    Text(context.l10n.tapForTool(_label(context, DrawTool.laser)), style: hintStyle),
                    const SizedBox(height: 4),
                    Text(context.l10n.doubleTapSelected, style: hintStyle),
                  ],
          ),
        ),
      ],
    );
  }

  Widget _panel({required Border border, required Color shadow}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: border,
        boxShadow: [BoxShadow(color: shadow, blurRadius: 20, spreadRadius: 5)],
      ),
    );
  }
}
