import 'package:flutter/material.dart';

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
    if (widget.isSpinning) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(SpinningRefreshIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSpinning && !oldWidget.isSpinning) {
      _controller.repeat();
    } else if (!widget.isSpinning && oldWidget.isSpinning) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: Icon(
        Icons.refresh_rounded,
        color: widget.isSpinning ? const Color(0xFF005B96) : Colors.white54,
        size: 20,
      ),
    );
  }
}
