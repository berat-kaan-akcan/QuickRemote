import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';

class GlowingDots extends StatelessWidget {
  final Animation<double> animation;
  const GlowingDots({super.key, required this.animation});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            // dalgalanma efekti için basit bir sinüs hesabı
            final val = math
                .sin((animation.value * math.pi) + (index * math.pi / 4))
                .abs();
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 6),
              width: 8 + (val * 4),
              height: 8 + (val * 4),
              decoration: BoxDecoration(
                color: AppColors.bluetoothLight.withValues(
                  alpha: 0.3 + (val * 0.7),
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.bluetoothLight.withValues(
                      alpha: val * 0.6,
                    ),
                    blurRadius: 4 + (val * 8),
                    spreadRadius: val * 3,
                  ),
                ],
              ),
            );
          }),
        );
      },
    );
  }
}
