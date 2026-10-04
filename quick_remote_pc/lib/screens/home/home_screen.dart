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
import '../../theme/app_colors.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WebSocketServerProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Static glow; an endless animation would cost GPU for nothing.
          Positioned(
            top: -35,
            left: -90,
            child: _glow(AppColors.primary, 300, 0.15),
          ),
          Positioned(
            bottom: -120,
            right: -40,
            child: _glow(AppColors.accent, 250, 0.1),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Column(
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accent.withValues(alpha: 0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.asset(
                            'assets/images/logo.png',
                            width: 44,
                            height: 44,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // One line each: wrapped header text took the room
                      // the QR card needs.
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'QuickRemote PC',
                                maxLines: 1,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            Text(
                              context.l10n.homeTagline,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (provider.isRunning)
                        IconButton(
                          icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
                          onPressed: () {
                            provider.triggerSlideStateUpdate();
                          },
                          tooltip: context.l10n.refreshSlideState,
                        ),
                      StatusChip(
                        isRunning: provider.isRunning,
                        clientCount: provider.clientCount,
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.settings_rounded, color: Colors.white70),
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

                  const SizedBox(height: 12),

                  if (Platform.isLinux) LinuxSetupPanel(provider: provider),

                  // Main Content
                  Expanded(
                    child: (provider.isRunning || provider.isStarting)
                        ? RunningDashboard(provider: provider)
                        : const StoppedDashboard(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _glow(Color color, double size, double alpha) => RepaintBoundary(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: alpha),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: alpha * 2), blurRadius: 100, spreadRadius: 40),
          ],
        ),
      ),
    );
