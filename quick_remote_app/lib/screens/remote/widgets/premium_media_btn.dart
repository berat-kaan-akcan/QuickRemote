import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PremiumMediaBtn extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool large;
  final bool glow;
  final VoidCallback? onTap;

  const PremiumMediaBtn({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    this.large = false,
    this.glow = false,
    this.onTap,
  });

  @override
  State<PremiumMediaBtn> createState() => _PremiumMediaBtnState();
}

class _PremiumMediaBtnState extends State<PremiumMediaBtn>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: enabled
          ? (_) {
              setState(() => _isPressed = false);
              HapticFeedback.lightImpact();
              widget.onTap!();
            }
          : null,
      onTapCancel: enabled ? () => setState(() => _isPressed = false) : null,
      child: AnimatedScale(
        scale: _isPressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedOpacity(
          opacity: enabled ? 1.0 : 0.45,
          duration: const Duration(milliseconds: 200),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: widget.large ? 16 : 14,
              vertical: widget.large ? 12 : 10,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  widget.color.withValues(alpha: 0.2),
                  widget.color.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: widget.color.withValues(alpha: 0.3)),
              boxShadow: [
                BoxShadow(
                  color: widget.color.withValues(alpha: widget.glow ? 0.4 : 0.1),
                  blurRadius: widget.glow ? 16 : 8,
                  spreadRadius: widget.glow ? 2 : 0,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  widget.icon,
                  color: widget.color,
                  size: widget.large ? 24 : 20,
                ),
                if (widget.large) ...[
                  const SizedBox(width: 8),
                  Text(
                    widget.label,
                    style: TextStyle(
                      color: widget.color,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
