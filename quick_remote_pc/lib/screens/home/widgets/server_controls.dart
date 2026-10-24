import 'dart:math' as math;

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
            padding: const EdgeInsets.all(AppSpace.xs),
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
/// The Stop key under the running server. A stopped server has none: the
/// big power button in the middle starts it.
class StopServerButton extends StatelessWidget {
  const StopServerButton({super.key, required this.provider});

  final WebSocketServerProvider provider;

  @override
  Widget build(BuildContext context) {
    final running = provider.isRunning || provider.isStarting;
    return AnimatedSize(
      duration: AppMotion.of(context, AppMotion.base),
      curve: AppMotion.enter,
      child: running
          ? Padding(
              padding: const EdgeInsets.only(top: AppSpace.sm),
              child: AppButton(
                label: context.l10n.stopServer,
                icon: Icons.power_settings_new_rounded,
                variant: AppButtonVariant.tonal,
                tone: AppTone.danger,
                height: 48,
                onPressed: provider.stopServer,
              ),
            )
          : const SizedBox(width: double.infinity),
    );
  }
}

/// The big round start button, with rings breathing around it.
class PowerButton extends StatefulWidget {
  const PowerButton({super.key, required this.onTap, required this.tooltip});

  final VoidCallback onTap;
  final String tooltip;

  @override
  State<PowerButton> createState() => _PowerButtonState();
}

class _PowerButtonState extends State<PowerButton> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AppMotion.reduced(context)) {
      _c.stop();
      _c.value = 0.25;
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    const size = 132.0;
    return SizedBox.square(
      dimension: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: RepaintBoundary(
              child: AnimatedBuilder(
                animation: _c,
                builder: (context, _) => CustomPaint(
                  painter: _BreathPainter(_c.value, p.primaryText, inner: size / 2),
                ),
              ),
            ),
          ),
          Pressable(
            onTap: widget.onTap,
            tooltip: widget.tooltip,
            semanticLabel: widget.tooltip,
            pressedScale: 0.94,
            hoveredScale: 1.05,
            borderRadius: AppRadius.all(size / 2),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                gradient: p.primaryGradient,
                shape: BoxShape.circle,
                boxShadow: AppShadows.glow(p.primary, strength: 1.4),
              ),
              foregroundDecoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  center: const Alignment(-0.5, -0.7),
                  radius: 0.9,
                  colors: [Colors.white.withValues(alpha: 0.22), Colors.white.withValues(alpha: 0)],
                ),
              ),
              child: const Icon(
                Icons.power_settings_new_rounded,
                size: 60,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BreathPainter extends CustomPainter {
  _BreathPainter(this.t, this.color, {required this.inner});

  final double t;
  final Color color;
  final double inner;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final outer = size.width / 2;
    for (var i = 0; i < 2; i++) {
      final phase = (t + i / 2) % 1;
      final r = inner + (outer - inner) * Curves.easeOut.transform(phase);
      final alpha = 0.35 * math.sin(math.pi * phase);
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = color.withValues(alpha: alpha),
      );
    }
  }

  @override
  bool shouldRepaint(_BreathPainter old) => old.t != t || old.color != color;
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
