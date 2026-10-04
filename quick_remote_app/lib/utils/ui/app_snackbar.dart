import 'package:flutter/material.dart';

import '../../widgets/ui/ui.dart';

enum SnackbarType { success, error, warning, info }

class AppSnackbar {
  static void show(
    BuildContext context, {
    required String message,
    SnackbarType type = SnackbarType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.hideCurrentSnackBar();

    final p = context.palette;
    final (tone, icon) = switch (type) {
      SnackbarType.success => (AppTone.success, Icons.check_circle_rounded),
      SnackbarType.error => (AppTone.danger, Icons.error_rounded),
      SnackbarType.warning => (AppTone.warning, Icons.warning_amber_rounded),
      SnackbarType.info => (AppTone.info, Icons.info_rounded),
    };
    final color = p.tone(tone);

    scaffoldMessenger.showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(AppSpace.md, 0, AppSpace.md, AppSpace.md),
        padding: EdgeInsets.zero,
        duration: duration,
        content: Semantics(
          liveRegion: true,
          child: Container(
            padding: const EdgeInsets.fromLTRB(AppSpace.sm, AppSpace.sm, AppSpace.md, AppSpace.sm),
            decoration: BoxDecoration(
              color: p.surfaceRaised,
              borderRadius: AppRadius.all(AppRadius.lg),
              border: Border.all(color: color.withValues(alpha: 0.35)),
              boxShadow: AppShadows.raised(p),
            ),
            child: Row(
              children: [
                IconBadge(icon: icon, color: color, size: 36),
                const SizedBox(width: AppSpace.sm),
                Expanded(
                  child: Text(
                    message,
                    style: AppType.body.copyWith(
                      color: p.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
