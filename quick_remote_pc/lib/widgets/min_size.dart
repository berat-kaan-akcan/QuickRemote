import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Lays the app out at least [minWidth] by [minHeight] and scales it down,
/// dialogs included, to fit a smaller window. `minimumSize` in main.dart does
/// not hold everywhere (KWin on Wayland let the window shrink below it);
/// below this width the banners and the header overflow, below this height
/// the header leaves no room for the scrolling content.
class MinSize extends StatelessWidget {
  const MinSize({super.key, required this.child});

  static const double minWidth = 380;
  static const double minHeight = 320;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        if (width == 0 || height == 0) return child;
        final scale = math.min(1.0, math.min(width / minWidth, height / minHeight));
        if (scale == 1) return child;
        return FittedBox(
          child: SizedBox(width: width / scale, height: height / scale, child: child),
        );
      },
    );
  }
}
