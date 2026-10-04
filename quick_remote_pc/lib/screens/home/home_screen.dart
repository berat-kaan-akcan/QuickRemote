import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/server_provider.dart';
import 'widgets/status_chip.dart';
import 'widgets/settings_dialog.dart';
import 'widgets/running_dashboard.dart';
import 'widgets/stopped_dashboard.dart';
import 'widgets/linux_setup_panel.dart';
import '../../l10n/app_language.dart';
import '../../widgets/ui/ui.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WebSocketServerProvider>();
    final p = context.palette;
    final running = provider.isRunning || provider.isStarting;

    return Scaffold(
      // Static light pools; an endless animation would cost GPU for nothing.
      body: AmbientBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.md, AppSpace.lg, AppSpace.md),
            child: Column(
              children: [
                // Header
                Row(
                  children: [
                    const BrandTile(size: 44),
                    const SizedBox(width: AppSpace.sm),
                    // One line each: wrapped header text took the room
                    // the QR card needs.
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: BrandWordmark(fontSize: 21, suffix: 'PC'),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            context.l10n.homeTagline,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppType.bodySmall.copyWith(color: p.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    if (provider.isRunning)
                      AppIconButton(
                        icon: Icons.refresh_rounded,
                        size: 40,
                        onPressed: () {
                          provider.triggerSlideStateUpdate();
                        },
                        tooltip: context.l10n.refreshSlideState,
                      ),
                    StatusChip(
                      isRunning: provider.isRunning,
                      clientCount: provider.clientCount,
                    ),
                    const SizedBox(width: AppSpace.xxs),
                    AppIconButton(
                      icon: Icons.settings_rounded,
                      size: 40,
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => const SettingsDialog(),
                        );
                      },
                      tooltip: context.l10n.settingsTitle,
                    ),
                  ],
                ),

                const SizedBox(height: AppSpace.md),

                if (Platform.isLinux) LinuxSetupPanel(provider: provider),

                // Main Content
                Expanded(
                  child: AnimatedSwitcher(
                    duration: AppMotion.of(context, AppMotion.slow),
                    switchInCurve: AppMotion.enter,
                    switchOutCurve: AppMotion.exit,
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(
                        scale: Tween<double>(begin: 0.97, end: 1).animate(animation),
                        child: child,
                      ),
                    ),
                    child: running
                        ? RunningDashboard(key: const ValueKey('running'), provider: provider)
                        : const StoppedDashboard(key: ValueKey('stopped')),
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
