import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quick_remote_shared/quick_remote_shared.dart';
import '../../../models/draw_tool.dart';

class ColorPickerSheet {
  static void show(BuildContext context, DrawTool tool, void Function(String) onSend) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final colors = [
          {
            'name': 'Kırmızı',
            'color': const Color(0xFFFF1744),
            'bgr': 255,
          },
          {
            'name': 'Mavi',
            'color': const Color(0xFF2979FF),
            'bgr': 16711680,
          },
          {
            'name': 'Yeşil',
            'color': const Color(0xFF00E676),
            'bgr': 65280,
          },
          {
            'name': 'Sarı',
            'color': const Color(0xFFFFEA00),
            'bgr': 65535,
          },
          {
            'name': 'Beyaz',
            'color': const Color(0xFFFFFFFF),
            'bgr': 16777215,
          },
          {
            'name': 'Mor',
            'color': const Color(0xFFD500F9),
            'bgr': 8388736,
          },
        ];

        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B).withValues(alpha: 0.85),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(32),
                ),
                border: Border(
                  top: BorderSide(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        tool == DrawTool.pen
                            ? Icons.edit
                            : Icons.border_color_rounded,
                        color: Colors.white.withValues(alpha: 0.9),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${tool == DrawTool.pen ? 'Kalem' : 'Vurgulayıcı'} Rengi',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Wrap(
                    spacing: 24,
                    runSpacing: 24,
                    alignment: WrapAlignment.center,
                    children: colors.map((c) {
                      final color = c['color'] as Color;
                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          final bgr = c['bgr'] as int;
                          // Pen and highlighter keep separate colors.
                          onSend(tool == DrawTool.pen
                              ? RemoteCommands.penColor(bgr)
                              : RemoteCommands.highlighterColor(bgr));
                          Navigator.pop(context);
                        },
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  width: 2.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: color.withValues(alpha: 0.4),
                                    blurRadius: 15,
                                    spreadRadius: 2,
                                  ),
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              c['name'] as String,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: TextButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Navigator.pop(context);
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.08),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'İptal',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
