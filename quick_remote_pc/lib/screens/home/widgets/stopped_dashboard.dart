import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../l10n/start_error_text.dart';
import '../../../providers/server_provider.dart';
import '../../../widgets/hover_scale.dart';
import '../../../widgets/status_snack_bar.dart';
import '../../../l10n/app_language.dart';
import '../../../theme/app_colors.dart';

class StoppedDashboard extends StatelessWidget {
  const StoppedDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          HoverScale(
            scale: 1.05,
            onTap: () async {
              final provider = context.read<WebSocketServerProvider>();
              try {
                await provider.startServer();
              } catch (e) {
                if (context.mounted) {
                  showStatusSnackBar(
                    context,
                    context.l10n.portsInUse,
                    kind: StatusKind.error,
                    duration: const Duration(seconds: 5),
                  );
                }
                return;
              }
              final startError = provider.startError;
              if (startError != null) {
                if (context.mounted) {
                  showStatusSnackBar(
                    context,
                    context.l10n.serverStartFailed(startErrorText(context.l10n, startError)),
                    kind: StatusKind.error,
                    duration: const Duration(seconds: 6),
                  );
                }
                return;
              }
              final actualPort = provider.server.port;
              if (actualPort != 8090 && context.mounted) {
                showStatusSnackBar(
                  context,
                  context.l10n.portFallback(actualPort),
                  kind: StatusKind.warning,
                );
              }
            },
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primary, AppColors.accent],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 30,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.power_settings_new_rounded,
                size: 64,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            context.l10n.serverStopped,
            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            context.l10n.serverStoppedHint,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 15, height: 1.5),
          ),
        ],
      ),
    );
  }
}
