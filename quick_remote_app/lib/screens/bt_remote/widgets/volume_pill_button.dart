import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// One segment of the Bluetooth volume pill: down, mute or up.
class VolumePillButton extends StatefulWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final bool isLeft;
  final bool isRight;

  const VolumePillButton({
    super.key,
    required this.icon,
    required this.color,
    this.onTap,
    this.isLeft = false,
    this.isRight = false,
  });

  @override
  State<VolumePillButton> createState() => VolumePillButtonState();
}

class VolumePillButtonState extends State<VolumePillButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => setState(() => _isPressed = true) : null,
        onTapUp: enabled
            ? (_) {
                setState(() => _isPressed = false);
                HapticFeedback.lightImpact();
                widget.onTap!();
              }
            : null,
        onTapCancel: enabled ? () => setState(() => _isPressed = false) : null,
        child: AnimatedOpacity(
          opacity: enabled ? (_isPressed ? 0.7 : 1.0) : 0.45,
          duration: const Duration(milliseconds: 100),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: _isPressed ? widget.color.withValues(alpha: 0.15) : Colors.transparent,
              borderRadius: BorderRadius.horizontal(
                left: widget.isLeft ? const Radius.circular(40) : Radius.zero,
                right: widget.isRight ? const Radius.circular(40) : Radius.zero,
              ),
            ),
            child: Icon(widget.icon, color: widget.color, size: 24),
          ),
        ),
      ),
    );
  }
}
