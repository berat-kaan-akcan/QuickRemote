import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../l10n/start_error_text.dart';
import '../../../providers/server_provider.dart';
import '../../../widgets/status_snack_bar.dart';
import '../../../l10n/app_language.dart';
import '../../../widgets/ui/ui.dart';

class StoppedDashboard extends StatelessWidget {
  const StoppedDashboard({super.key});

  Future<void> _start(BuildContext context) async {
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
          context.l10n.serverStartFailed(startErrorText(context.l10n, startError)),
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

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FadeSlideIn(
              child: _PowerButton(
                tooltip: context.l10n.startServer,
                onTap: () => _start(context),
              ),
            ),
            const SizedBox(height: AppSpace.xl),
            FadeSlideIn(
              index: 1,
              child: Text(
                context.l10n.serverStopped,
                textAlign: TextAlign.center,
                style: AppType.headline.copyWith(color: p.textPrimary),
              ),
            ),
            const SizedBox(height: AppSpace.sm),
            FadeSlideIn(
              index: 2,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: Text(
                  context.l10n.serverStoppedHint,
                  textAlign: TextAlign.center,
                  style: AppType.body.copyWith(color: p.textSecondary, height: 1.5),
                ),
              ),
            ),
            const SizedBox(height: AppSpace.xl),
            FadeSlideIn(
              index: 3,
              child: AppButton(
                label: context.l10n.startServer,
                icon: Icons.play_arrow_rounded,
                expand: false,
                onPressed: () => _start(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The big round start button, with rings breathing around it.
class _PowerButton extends StatefulWidget {
  const _PowerButton({required this.onTap, required this.tooltip});

  final VoidCallback onTap;
  final String tooltip;

  @override
  State<_PowerButton> createState() => _PowerButtonState();
}

class _PowerButtonState extends State<_PowerButton> with SingleTickerProviderStateMixin {
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
