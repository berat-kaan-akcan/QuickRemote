import 'dart:io';
import 'dart:math' as math;
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
    final running = provider.isRunning || provider.isStarting;

    return Scaffold(
      // Static light pools; an endless animation would cost GPU for nothing.
      body: AmbientBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.md, AppSpace.lg, AppSpace.md),
            child: Column(
              children: [
                _Header(provider: provider),

                const SizedBox(height: AppSpace.md),

                // Main Content. A short window scrolls instead of squeezing
                // the dashboard below what it needs.
                Expanded(
                  child: CustomScrollView(
                    slivers: [
                      if (Platform.isLinux) SliverToBoxAdapter(child: LinuxSetupPanel(provider: provider)),
                      SliverLayoutBuilder(
                        builder: (context, constraints) {
                          final remaining = constraints.viewportMainAxisExtent - constraints.precedingScrollExtent;
                          return SliverToBoxAdapter(
                            child: SizedBox(
                              height: math.max(remaining, _minDashboardHeight(provider)),
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
                          );
                        },
                      ),
                    ],
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

/// Height the dashboard keeps however short the window: the QR code shrinks
/// to fit, the status rows and the stop button do not.
double _minDashboardHeight(WebSocketServerProvider provider) =>
    460 + 64.0 * provider.connectedClients.length + (provider.pairingPaused ? 64 : 0);

class _Header extends StatelessWidget {
  const _Header({required this.provider});

  final WebSocketServerProvider provider;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
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
    );
  }
}
