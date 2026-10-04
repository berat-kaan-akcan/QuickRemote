import 'package:flutter/material.dart';

import '../../theme/app_palette.dart';
import '../../theme/app_tokens.dart';
import '../../theme/app_typography.dart';
import 'app_button.dart';

/// A small status capsule: a dot (pulsing while [busy]) and a label.
class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.label,
    required this.color,
    this.busy = false,
    this.icon,
  });

  final String label;
  final Color color;

  /// Shows a spinner in place of the dot.
  final bool busy;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AnimatedContainer(
      duration: AppMotion.of(context, AppMotion.base),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: p.isDark ? 0.14 : 0.10),
        borderRadius: AppRadius.all(AppRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.32)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (busy)
            SizedBox.square(
              dimension: 10,
              child: CircularProgressIndicator(strokeWidth: 2, color: color),
            )
          else if (icon != null)
            Icon(icon, size: 14, color: color)
          else
            PulseDot(color: color, size: 7),
          const SizedBox(width: 6),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppType.labelSmall.copyWith(color: color, fontSize: 11.5),
          ),
        ],
      ),
    );
  }
}

/// A dot with a soft halo that breathes, for live states.
class PulseDot extends StatefulWidget {
  const PulseDot({super.key, required this.color, this.size = 8, this.animate = true});

  final Color color;
  final double size;
  final bool animate;

  @override
  State<PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<PulseDot> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(PulseDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    final run = widget.animate && !AppMotion.reduced(context);
    if (run && !_c.isAnimating) {
      _c.repeat();
    } else if (!run && _c.isAnimating) {
      _c.stop();
      _c.value = 0;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    return SizedBox.square(
      dimension: s,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = Curves.easeOut.transform(_c.value);
          return CustomPaint(
            painter: _PulsePainter(widget.color, t, _c.isAnimating),
          );
        },
      ),
    );
  }
}

class _PulsePainter extends CustomPainter {
  _PulsePainter(this.color, this.t, this.halo);

  final Color color;
  final double t;
  final bool halo;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    if (halo) {
      canvas.drawCircle(c, r * (1 + 1.4 * t), Paint()..color = color.withValues(alpha: 0.45 * (1 - t)));
    }
    canvas.drawCircle(c, r, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_PulsePainter old) => old.t != t || old.color != color || old.halo != halo;
}

/// A tinted message row: errors, warnings and notes inside a screen.
class InlineAlert extends StatelessWidget {
  const InlineAlert({
    super.key,
    required this.message,
    this.tone = AppTone.info,
    this.icon,
    this.actionLabel,
    this.onAction,
    this.title,
    this.dense = false,
  });

  final String message;
  final String? title;
  final AppTone tone;
  final IconData? icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool dense;

  IconData get _icon =>
      icon ??
      switch (tone) {
        AppTone.success => Icons.check_circle_rounded,
        AppTone.warning => Icons.warning_amber_rounded,
        AppTone.danger => Icons.error_rounded,
        _ => Icons.info_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final color = p.tone(tone);
    return Semantics(
      liveRegion: tone == AppTone.danger,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: AppSpace.md - 2, vertical: dense ? AppSpace.xs + 2 : AppSpace.sm),
        decoration: BoxDecoration(
          color: color.withValues(alpha: p.isDark ? 0.12 : 0.08),
          borderRadius: AppRadius.all(AppRadius.md),
          border: Border.all(color: color.withValues(alpha: p.isDark ? 0.30 : 0.24)),
        ),
        child: Row(
          crossAxisAlignment: title == null ? CrossAxisAlignment.center : CrossAxisAlignment.start,
          children: [
            Icon(_icon, color: color, size: dense ? 18 : 20),
            const SizedBox(width: AppSpace.sm - 2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (title != null) ...[
                    Text(title!, style: AppType.titleSmall.copyWith(color: color, fontSize: 14)),
                    const SizedBox(height: 2),
                  ],
                  Text(
                    message,
                    style: AppType.bodySmall.copyWith(
                      color: title == null ? color : p.textSecondary,
                      fontWeight: title == null ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(width: AppSpace.xs),
              AppButton(
                label: actionLabel!,
                onPressed: onAction,
                variant: AppButtonVariant.tonal,
                tone: tone,
                expand: false,
                height: 36,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Icon in soft concentric rings, a title, a line of help and an action:
/// for empty lists, failures and unsupported states.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
    this.tone = AppTone.primary,
    this.compact = false,
  });

  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;
  final AppTone tone;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final color = p.tone(tone);
    final ring = compact ? 76.0 : 120.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox.square(
          dimension: ring,
          child: CustomPaint(
            painter: _RingsPainter(color: color, isDark: p.isDark),
            child: Center(
              child: Icon(icon, color: color, size: compact ? 30 : 44),
            ),
          ),
        ),
        SizedBox(height: compact ? AppSpace.sm : AppSpace.lg),
        Text(
          title,
          textAlign: TextAlign.center,
          style: (compact ? AppType.titleSmall : AppType.title).copyWith(color: p.textPrimary),
        ),
        if (message != null) ...[
          const SizedBox(height: AppSpace.xs),
          Text(
            message!,
            textAlign: TextAlign.center,
            style: AppType.bodySmall.copyWith(color: p.textSecondary, fontSize: compact ? 13 : 14),
          ),
        ],
        if (action != null) ...[
          SizedBox(height: compact ? AppSpace.md : AppSpace.xl),
          action!,
        ],
      ],
    );
  }
}

class _RingsPainter extends CustomPainter {
  _RingsPainter({required this.color, required this.isDark});

  final Color color;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    canvas.drawCircle(c, r, Paint()..color = color.withValues(alpha: isDark ? 0.06 : 0.05));
    canvas.drawCircle(c, r * 0.74, Paint()..color = color.withValues(alpha: isDark ? 0.10 : 0.08));
    canvas.drawCircle(
      c,
      r * 0.74,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = color.withValues(alpha: 0.22),
    );
    canvas.drawCircle(c, r * 0.5, Paint()..color = color.withValues(alpha: isDark ? 0.16 : 0.12));
  }

  @override
  bool shouldRepaint(_RingsPainter old) => old.color != color || old.isDark != isDark;
}

/// A placeholder block with a sweeping sheen while content loads.
class Skeleton extends StatefulWidget {
  const Skeleton({super.key, this.width, required this.height, this.radius = AppRadius.sm});

  final double? width;
  final double height;
  final double radius;

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AppMotion.reduced(context)) {
      _c.stop();
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
    final base = p.surfaceSunken;
    final shine = Color.alphaBlend(p.textPrimary.withValues(alpha: p.isDark ? 0.06 : 0.05), base);
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final x = -1.5 + 3 * _c.value;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: AppRadius.all(widget.radius),
            gradient: LinearGradient(
              begin: Alignment(x - 1, 0),
              end: Alignment(x + 1, 0),
              colors: [base, shine, base],
            ),
          ),
        );
      },
    );
  }
}

/// Shows [child] with a fade and a size change, or collapses when null.
class Reveal extends StatelessWidget {
  const Reveal({super.key, this.child, this.alignment = Alignment.topCenter});

  final Widget? child;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final duration = AppMotion.of(context, AppMotion.base);
    return AnimatedSize(
      duration: duration,
      curve: AppMotion.standard,
      alignment: alignment,
      child: AnimatedSwitcher(
        duration: duration,
        switchInCurve: AppMotion.enter,
        switchOutCurve: AppMotion.exit,
        child: child ?? const SizedBox(width: double.infinity),
      ),
    );
  }
}
