import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../l10n/start_error_text.dart';
import '../../../providers/server_provider.dart';
import '../../../widgets/status_snack_bar.dart';
import '../../../l10n/app_language.dart';
import '../../../widgets/ui/ui.dart';
import 'home_card.dart';

/// Starts the server and says so when it could not, or had to take
/// another port.
Future<void> startServerFromUi(BuildContext context) async {
  final provider = context.read<WebSocketServerProvider>();
  try {
    await provider.startServer();
  } catch (e) {
    if (context.mounted) {
      showStatusSnackBar(
        context,
        context.l10n.portsInUse,
        kind: StatusKind.error,
        duration: const Duration(seconds: 5),
      );
    }
    return;
  }
  final startError = provider.startError;
  if (startError != null) {
    if (context.mounted) {
      showStatusSnackBar(
        context,
        context.l10n.serverStartFailed(
          startErrorText(context.l10n, startError),
        ),
        kind: StatusKind.error,
        duration: const Duration(seconds: 6),
      );
    }
    return;
  }
  final actualPort = provider.server.port;
  if (actualPort != 8090 && context.mounted) {
    showStatusSnackBar(
      context,
      context.l10n.portFallback(actualPort),
      kind: StatusKind.warning,
    );
  }
}

/// The stopped server: the big power button and what starting it is for. In
/// the narrow window in a dashed card that fills the room above the button.
class StoppedPanel extends StatelessWidget {
  const StoppedPanel({super.key, this.framed = true});

  final bool framed;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final content = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        FadeSlideIn(
          child: Padding(
            padding: const EdgeInsets.all(AppSpace.xl),
            child: PowerButton(
              tooltip: context.l10n.startServer,
              onTap: () => startServerFromUi(context),
            ),
          ),
        ),
        const SizedBox(height: AppSpace.xs),
        FadeSlideIn(
          index: 1,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: framed ? 280 : 320),
            child: Text(
              context.l10n.serverStoppedHint,
              textAlign: TextAlign.center,
              style: AppType.body.copyWith(
                color: p.textSecondary,
                fontSize: framed ? 13.5 : 14,
                height: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
    if (!framed) return Center(child: SingleChildScrollView(child: content));
    return CustomPaint(
      foregroundPainter: _DashedBorderPainter(
        color: p.border,
        radius: HomeCard.radius,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpace.md),
        decoration: BoxDecoration(
          color: p.surface.withValues(alpha: p.isDark ? 0.6 : 0.8),
          borderRadius: AppRadius.all(HomeCard.radius),
        ),
        child: Center(child: content),
      ),
    );
  }
}

/// The full-width key under everything: green Start while stopped, red
/// Stop while the server starts or runs.
class ServerToggleButton extends StatelessWidget {
  const ServerToggleButton({super.key, required this.provider});

  final WebSocketServerProvider provider;

  @override
  Widget build(BuildContext context) {
    final running = provider.isRunning || provider.isStarting;
    return AnimatedSwitcher(
      duration: AppMotion.of(context, AppMotion.base),
      child: running
          ? AppButton(
              key: const ValueKey('stop'),
              label: context.l10n.stopServer,
              icon: Icons.power_settings_new_rounded,
              variant: AppButtonVariant.tonal,
              tone: AppTone.danger,
              height: 48,
              onPressed: provider.stopServer,
            )
          : AppButton(
              key: const ValueKey('start'),
              label: context.l10n.startServer,
              icon: Icons.play_arrow_rounded,
              tone: AppTone.success,
              height: 48,
              onPressed: () => startServerFromUi(context),
            ),
    );
  }
}

/// The big round start button in two soft rings.
class PowerButton extends StatelessWidget {
  const PowerButton({super.key, required this.onTap, required this.tooltip});

  final VoidCallback onTap;
  final String tooltip;

  static const size = 132.0;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Pressable(
      onTap: onTap,
      tooltip: tooltip,
      semanticLabel: tooltip,
      pressedScale: 0.94,
      hoveredScale: 1.05,
      borderRadius: AppRadius.all(size / 2),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [p.primaryBright, p.primary, p.primaryDeep],
            stops: const [0, 0.55, 1],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: p.primaryText.withValues(alpha: 0.07),
              spreadRadius: 22,
            ),
            BoxShadow(
              color: p.primaryText.withValues(alpha: 0.04),
              spreadRadius: 44,
            ),
            ...AppShadows.glow(p.primaryBright, strength: 1.4),
          ],
        ),
        child: Icon(
          Icons.power_settings_new_rounded,
          size: 60,
          color: p.onPrimary,
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    ).deflate(0.5);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final metric in (Path()..addRRect(rrect)).computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 9) {
        canvas.drawPath(metric.extractPath(d, d + 5), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) =>
      old.color != color || old.radius != radius;
}
