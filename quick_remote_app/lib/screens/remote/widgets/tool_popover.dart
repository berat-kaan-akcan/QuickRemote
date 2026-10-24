import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quick_remote_shared/quick_remote_shared.dart';
import '../../../models/draw_tool.dart';
import '../../../l10n/app_language.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/ui/ui.dart';
import 'touchpad_surface.dart';

/// The six inks of the pen and highlighter: the swatch and the BGR value
/// the PC takes.
List<(String, Color, int)> inkSwatches(BuildContext context) => [
      (context.l10n.colorRed, AppColors.inkRed, 255),
      (context.l10n.colorBlue, AppColors.inkBlue, 16711680),
      (context.l10n.colorGreen, AppColors.inkGreen, 65280),
      (context.l10n.colorYellow, AppColors.inkYellow, 65535),
      (context.l10n.colorWhite, AppColors.inkWhite, 16777215),
      (context.l10n.colorPurple, AppColors.inkPurple, 8388736),
    ];

/// A small panel above the tool bar with a notch pointing down at the tool
/// at [anchor] (0 the left edge, 1 the right).
class ToolPopover extends StatelessWidget {
  const ToolPopover({super.key, required this.anchor, required this.child});

  final double anchor;
  final Widget child;

  static const _notch = 8.0;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: _notch),
      child: CustomPaint(
        painter: _NotchPainter(anchor: anchor, fill: p.surfaceRaised, edge: p.border),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, AppSpace.sm, 14, AppSpace.sm),
          decoration: BoxDecoration(
            color: p.surfaceRaised,
            borderRadius: AppRadius.all(AppRadius.lg),
            border: Border.all(color: p.border),
            boxShadow: AppShadows.raised(p),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _NotchPainter extends CustomPainter {
  _NotchPainter({required this.anchor, required this.fill, required this.edge});

  final double anchor;
  final Color fill;
  final Color edge;

  @override
  void paint(Canvas canvas, Size size) {
    const n = ToolPopover._notch;
    final x = (size.width * anchor).clamp(AppRadius.lg + n, size.width - AppRadius.lg - n);
    final path = Path()
      ..moveTo(x - n, size.height - 1)
      ..lineTo(x, size.height + n)
      ..lineTo(x + n, size.height - 1);
    canvas.drawPath(path, Paint()..color = fill);
    canvas.drawPath(
      path,
      Paint()
        ..color = edge
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(_NotchPainter old) => old.anchor != anchor || old.fill != fill || old.edge != edge;
}

/// The pen's or highlighter's six inks; [selected] is the one last sent.
class InkPicker extends StatelessWidget {
  const InkPicker({super.key, required this.tool, required this.selected, required this.onPicked, required this.onClose});

  final DrawTool tool;
  final int? selected;

  /// Gets the BGR value.
  final ValueChanged<int> onPicked;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final swatches = inkSwatches(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(tool.icon, color: tool.colorIn(p), size: 18),
            const SizedBox(width: AppSpace.xs),
            Expanded(
              child: Text(
                tool == DrawTool.pen ? context.l10n.penColorTitle : context.l10n.highlighterColorTitle,
                style: AppType.titleSmall.copyWith(color: p.textPrimary, fontSize: 14),
              ),
            ),
            AppIconButton(icon: Icons.close_rounded, tooltip: context.l10n.close, size: 32, iconSize: 20, onPressed: onClose),
          ],
        ),
        const SizedBox(height: AppSpace.xs),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (final (name, color, bgr) in swatches)
              Pressable(
                semanticLabel: name,
                selected: bgr == selected,
                pressedScale: 0.88,
                borderRadius: AppRadius.all(AppRadius.pill),
                onTap: () {
                  HapticFeedback.lightImpact();
                  onPicked(bgr);
                },
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: bgr == selected ? p.textPrimary : p.textPrimary.withValues(alpha: 0), width: 2.5),
                      ),
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(color: p.surfaceRaised, width: 3),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpace.xxs),
                    ExcludeSemantics(
                      child: Text(name, style: AppType.bodySmall.copyWith(color: p.textSecondary, fontSize: 10.5)),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// Why the pen and highlighter take no color in this program.
class NoColorNote extends StatelessWidget {
  const NoColorNote({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info_outline_rounded, color: p.info, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text.rich(
            TextSpan(children: [
              TextSpan(
                text: context.l10n.colorUnavailableTitle,
                style: TextStyle(color: p.textPrimary, fontWeight: FontWeight.w700),
              ),
              TextSpan(text: ' ${context.l10n.colorUnavailableBody}'),
            ]),
            style: AppType.bodySmall.copyWith(color: p.textSecondary, fontSize: 12.5),
          ),
        ),
      ],
    );
  }
}

/// What the laser is, from a PC whose overlay draws it: the dot, the
/// spotlight (the screen darkened but for a circle under the finger) or a
/// magnifier (Windows PCs only).
enum LaserStyle {
  laser(RemoteCommands.modeLaser, Icons.highlight_rounded),
  spotlight(RemoteCommands.modeSpotlight, Icons.flashlight_on_rounded),
  zoom(RemoteCommands.modeZoom, Icons.zoom_in_rounded);

  const LaserStyle(this.command, this.icon);

  /// What a touch sends.
  final String command;
  final IconData icon;

  String label(BuildContext context) => switch (this) {
    LaserStyle.laser => context.l10n.toolLaser,
    LaserStyle.spotlight => context.l10n.toolSpotlight,
    LaserStyle.zoom => context.l10n.toolZoom,
  };
}

/// Picks the [LaserStyle]; [zoom]: the PC has a magnifier.
class LaserStylePicker extends StatelessWidget {
  const LaserStylePicker({
    super.key,
    required this.style,
    required this.zoom,
    required this.onPicked,
    required this.onClose,
    this.spotlight = true,
  });

  final LaserStyle style;
  final bool zoom;

  /// The PC has the spotlight (from a PC that sends caps, it may not).
  final bool spotlight;
  final ValueChanged<LaserStyle> onPicked;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(DrawTool.laser.icon, color: DrawTool.laser.colorIn(p), size: 18),
            const SizedBox(width: AppSpace.xs),
            Expanded(
              child: Text(
                context.l10n.laserStyleTitle,
                style: AppType.titleSmall.copyWith(color: p.textPrimary, fontSize: 14),
              ),
            ),
            AppIconButton(icon: Icons.close_rounded, tooltip: context.l10n.close, size: 32, iconSize: 20, onPressed: onClose),
          ],
        ),
        const SizedBox(height: AppSpace.xs),
        AppSegmented<LaserStyle>(
          selected: style,
          onChanged: (value) {
            HapticFeedback.lightImpact();
            onPicked(value);
          },
          segments: [
            for (final option in LaserStyle.values)
              if ((option != LaserStyle.zoom || zoom) && (option != LaserStyle.spotlight || spotlight))
                AppSegment(value: option, label: option.label(context), icon: option.icon),
          ],
        ),
        const SizedBox(height: AppSpace.xs),
        Text(
          context.l10n.laserStyleSpotlightNote,
          style: AppType.bodySmall.copyWith(color: p.textSecondary, fontSize: 12),
        ),
      ],
    );
  }
}
