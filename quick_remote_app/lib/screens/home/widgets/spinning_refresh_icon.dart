import 'package:flutter/material.dart';

import '../../../widgets/ui/ui.dart';

class SpinningRefreshIcon extends StatefulWidget {
  final bool isSpinning;
  const SpinningRefreshIcon({super.key, required this.isSpinning});

  @override
  State<SpinningRefreshIcon> createState() => _SpinningRefreshIconState();
}

class _SpinningRefreshIconState extends State<SpinningRefreshIcon> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(SpinningRefreshIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  bool _repeating = false;

  void _sync() {
    final spin = widget.isSpinning && !AppMotion.reduced(context);
    if (spin && !_repeating) {
      _repeating = true;
      _controller.repeat();
    } else if (!spin && _repeating) {
      _repeating = false;
      // Finish the turn instead of freezing at an angle.
      _controller.animateTo(1, duration: AppMotion.of(context, AppMotion.slow)).whenComplete(() {
        if (mounted && !_repeating) _controller.value = 0;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return RotationTransition(
      turns: _controller,
      child: Icon(
        Icons.refresh_rounded,
        color: widget.isSpinning ? p.primaryText : p.textSecondary,
        size: 20,
      ),
    );
  }
}
