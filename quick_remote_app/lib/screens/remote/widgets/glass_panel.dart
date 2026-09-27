import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class GlassPanel extends StatelessWidget {
  final Widget child;
  final List<Color> gradientColors;
  final Color borderColor;

  const GlassPanel({
    super.key,
    required this.child,
    this.gradientColors = const [Colors.white10, Colors.white12],
    this.borderColor = Colors.white12,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor),
          ),
          child: child,
        ),
      ),
    );
  }
}
