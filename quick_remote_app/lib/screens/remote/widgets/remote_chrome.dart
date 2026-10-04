import 'package:flutter/material.dart';

import '../../settings/settings_screen.dart';
import '../../../l10n/app_language.dart';
import '../../../theme/app_colors.dart';

/// The app bar row of the Wi-Fi and Bluetooth remotes: logo, connection
/// subtitle, status chip, settings and close.
class RemoteHeader extends StatelessWidget {
  const RemoteHeader({
    super.key,
    required this.subtitle,
    required this.isConnected,
    required this.onClose,
    this.isConnecting = false,
    this.onReconnect,
  });

  final Widget subtitle;
  final bool isConnected;
  final bool isConnecting;

  /// Shows a reconnect button when set.
  final VoidCallback? onReconnect;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset('assets/images/logo.png', width: 36, height: 36, fit: BoxFit.cover),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'QuickRemote',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              subtitle,
            ],
          ),
        ),
        if (onReconnect != null)
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white70, size: 22),
            onPressed: onReconnect,
            tooltip: context.l10n.remoteReconnect,
          ),
        _StatusChip(isConnected: isConnected, isConnecting: isConnecting),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.settings_rounded, color: Colors.white54, size: 22),
          tooltip: context.l10n.homeSettingsTooltip,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white54, size: 22),
          tooltip: context.l10n.close,
          onPressed: onClose,
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.isConnected, required this.isConnecting});

  final bool isConnected;
  final bool isConnecting;

  @override
  Widget build(BuildContext context) {
    final color = isConnected ? AppColors.success : AppColors.danger;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isConnected && isConnecting)
            Container(
              width: 10,
              height: 10,
              margin: const EdgeInsets.only(right: 5),
              child: const CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.danger),
              ),
            )
          else
            Container(
              width: 7,
              height: 7,
              margin: const EdgeInsets.only(right: 5),
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          Text(
            isConnected
                ? context.l10n.statusConnected
                : isConnecting
                    ? context.l10n.homeConnecting
                    : context.l10n.statusDisconnected,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }
}

/// Controls, touchpad and media tabs.
class RemoteBottomNav extends StatelessWidget {
  const RemoteBottomNav({super.key, required this.currentTab, required this.onTap});

  final int currentTab;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.background,
        selectedItemColor: Theme.of(context).colorScheme.secondary,
        unselectedItemColor: Colors.white38,
        currentIndex: currentTab.clamp(0, 2),
        onTap: onTap,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.gamepad_rounded),
            label: context.l10n.remoteTabControls,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.touch_app_rounded),
            label: context.l10n.remoteTabTouchpad,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.queue_music_rounded),
            label: context.l10n.remoteTabMedia,
          ),
        ],
      ),
    );
  }
}
