import 'package:flutter/material.dart';

import '../../theme/app_tokens.dart';

/// Fades [child] in while it rises a few pixels, once, when first built.
/// Items of a list pass their [index] for a staggered entrance.
///
/// Uses no timers: the delay is the start of the animation's interval.
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.index = 0,
    this.offset = 14,
    this.duration = AppMotion.slow,
  });

  final Widget child;

  /// Position in a staggered group; delays are capped after a few items.
  final int index;

  /// Distance in logical pixels the child rises.
  final double offset;
  final Duration duration;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn> with SingleTickerProviderStateMixin {
  static const _maxStaggered = 8;

  late final Duration _delay = AppMotion.stagger * widget.index.clamp(0, _maxStaggered);
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.duration + _delay,
  );
  late final Animation<double> _t = CurvedAnimation(
    parent: _c,
    curve: Interval(
      _delay.inMicroseconds / (widget.duration + _delay).inMicroseconds,
      1,
      curve: AppMotion.enter,
    ),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (AppMotion.reduced(context)) {
      _c.value = 1;
    } else {
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _t,
      child: widget.child,
      builder: (context, child) {
        final t = _t.value;
        return Opacity(
          opacity: t,
          child: Transform.translate(offset: Offset(0, widget.offset * (1 - t)), child: child),
        );
      },
    );
  }
}
