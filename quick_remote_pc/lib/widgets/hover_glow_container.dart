import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class HoverGlowContainer extends StatefulWidget {
  final Widget child;

  const HoverGlowContainer({super.key, required this.child});

  @override
  State<HoverGlowContainer> createState() => _HoverGlowContainerState();
}

class _HoverGlowContainerState extends State<HoverGlowContainer> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            if (_isHovered)
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.4),
                blurRadius: 30,
                spreadRadius: 2,
              )
          ],
        ),
        child: widget.child,
      ),
    );
  }
}
