import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/server_provider.dart';
import 'widgets/status_chip.dart';
import 'widgets/settings_dialog.dart';
import 'widgets/running_dashboard.dart';
import 'widgets/stopped_dashboard.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _bgAnimController;

  @override
  void initState() {
    super.initState();
    _bgAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _bgAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WebSocketServerProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Stack(
        children: [
          // Background Blobs
          AnimatedBuilder(
            animation: _bgAnimController,
            builder: (context, child) {
              return Positioned(
                top: -50 + (_bgAnimController.value * 30),
                left: -100 + (_bgAnimController.value * 20),
                child: RepaintBoundary(
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF005B96).withValues(alpha: 0.15),
                      boxShadow: [
                        BoxShadow(color: const Color(0xFF005B96).withValues(alpha: 0.2), blurRadius: 100, spreadRadius: 40)
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          AnimatedBuilder(
            animation: _bgAnimController,
            builder: (context, child) {
              return Positioned(
                bottom: -100 - (_bgAnimController.value * 40),
                right: -50 + (_bgAnimController.value * 20),
                child: RepaintBoundary(
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF00BCD4).withValues(alpha: 0.1),
                      boxShadow: [
                        BoxShadow(color: const Color(0xFF00BCD4).withValues(alpha: 0.2), blurRadius: 100, spreadRadius: 40)
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
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
                              color: const Color(0xFF00BCD4).withValues(alpha: 0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.asset(
                            'assets/images/logo.png', 
                            width: 52, 
                            height: 52,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'QuickRemote PC',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Sunum Kontrol Merkezi',
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
                          tooltip: 'Slayt Durumunu Yenile',
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
                        tooltip: 'Ayarlar',
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

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
