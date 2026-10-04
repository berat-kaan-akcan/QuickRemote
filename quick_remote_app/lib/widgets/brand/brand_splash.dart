import 'package:flutter/material.dart';

import '../../theme/app_palette.dart';
import '../../theme/app_tokens.dart';
import '../../theme/app_typography.dart';
import 'brand_mark.dart';

/// The launch intro, laid over the first screen: the icon tile draws its
/// mark, the laser dot lights up, the name rises, then the whole layer fades
/// away. The screen below is built from the start, so nothing waits on it.
///
/// Skipped when the system asks for less motion. Lasts about 1.3 s and ignores
/// touches only while it is opaque.
class BrandSplash extends StatefulWidget {
  const BrandSplash({super.key, required this.tagline});

  final String tagline;

  @override
  State<BrandSplash> createState() => _BrandSplashState();
}

class _BrandSplashState extends State<BrandSplash> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1350),
  );
  bool _done = false;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (AppMotion.reduced(context)) {
      _done = true;
      return;
    }
    _c.forward().whenComplete(() {
      if (mounted) setState(() => _done = true);
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  static double _interval(double t, double a, double b, [Curve curve = Curves.linear]) =>
      curve.transform(((t - a) / (b - a)).clamp(0.0, 1.0));

  @override
  Widget build(BuildContext context) {
    if (_done) return const SizedBox.shrink();
    final p = context.palette;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = _c.value;
        final fadeOut = _interval(t, 0.76, 1, AppMotion.exit);
        final tileIn = _interval(t, 0, 0.18, AppMotion.enter);
        final draw = _interval(t, 0.08, 0.66);
        final textIn = _interval(t, 0.38, 0.66, AppMotion.enter);
        return IgnorePointer(
          ignoring: fadeOut > 0.5,
          child: Opacity(
            opacity: 1 - fadeOut,
            child: ColoredBox(
              color: p.background,
              child: Center(
                child: Transform.scale(
                  scale: 1 + 0.06 * fadeOut,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Opacity(
                        opacity: tileIn,
                        child: Transform.scale(
                          scale: 0.86 + 0.14 * tileIn,
                          child: BrandTile(size: 104, progress: draw),
                        ),
                      ),
                      const SizedBox(height: AppSpace.xl),
                      Opacity(
                        opacity: textIn,
                        child: Transform.translate(
                          offset: Offset(0, 10 * (1 - textIn)),
                          child: Column(
                            children: [
                              const BrandWordmark(fontSize: 30),
                              const SizedBox(height: AppSpace.xs),
                              Text(
                                widget.tagline,
                                textAlign: TextAlign.center,
                                style: AppType.bodySmall.copyWith(color: p.textSecondary),
                              ),
                            ],
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
      },
    );
  }
}
