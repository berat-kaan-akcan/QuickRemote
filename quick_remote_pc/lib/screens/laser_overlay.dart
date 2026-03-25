import 'dart:async';
import 'package:flutter/material.dart';

/// Laser pointer overlay — a transparent, click-through window
/// showing a glowing red dot that follows the mouse cursor.
class LaserOverlay extends StatefulWidget {
  final Stream<Offset> positionStream;
  final VoidCallback onClose;

  const LaserOverlay({
    super.key,
    required this.positionStream,
    required this.onClose,
  });

  @override
  State<LaserOverlay> createState() => _LaserOverlayState();
}

class _LaserOverlayState extends State<LaserOverlay>
    with SingleTickerProviderStateMixin {
  Offset _position = Offset.zero;
  StreamSubscription<Offset>? _sub;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _sub = widget.positionStream.listen((pos) {
      if (mounted) {
        setState(() => _position = pos);
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Laser dot
          Positioned(
            left: _position.dx - 12,
            top: _position.dy - 12,
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                final scale = 1.0 + (_pulseController.value * 0.15);
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFFF1744).withValues(alpha: 0.9),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF1744).withValues(alpha: 0.6),
                          blurRadius: 20,
                          spreadRadius: 8,
                        ),
                        BoxShadow(
                          color: const Color(0xFFFF5252).withValues(alpha: 0.3),
                          blurRadius: 40,
                          spreadRadius: 15,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
