import 'package:flutter/material.dart';

class StatusChip extends StatelessWidget {
  final bool isRunning;
  final int clientCount;

  const StatusChip({super.key, required this.isRunning, required this.clientCount});

  @override
  Widget build(BuildContext context) {
    final color = (!isRunning || clientCount == 0) 
        ? const Color(0xFFFF5252) 
        : const Color(0xFF4CAF50);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 8, spreadRadius: 2),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            isRunning ? '$clientCount Bağlı' : 'Kapalı',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
