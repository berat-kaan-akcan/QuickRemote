import 'package:flutter/material.dart';

import '../../settings/settings_screen.dart';
import '../../../l10n/app_language.dart';
import '../../../widgets/ui/ui.dart';

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
    final p = context.palette;
    // On narrow phones the status chip shrinks to its dot.
    final compact = MediaQuery.sizeOf(context).width < 360;
    return Row(
      children: [
        const BrandTile(size: 38, shadow: false),
        const SizedBox(width: AppSpace.sm - 2),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const BrandWordmark(fontSize: 17),
              const SizedBox(height: 2),
              DefaultTextStyle.merge(
                style: AppType.mono.copyWith(
                  color: p.textMuted,
                  fontSize: 11.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                child: subtitle,
              ),
            ],
          ),
        ),
        if (onReconnect != null)
          AppIconButton(
            icon: Icons.refresh_rounded,
            tooltip: context.l10n.remoteReconnect,
            color: p.primaryText,
            size: 40,
            onPressed: onReconnect,
          ),
        _StatusChip(isConnected: isConnected, isConnecting: isConnecting, compact: compact),
        const SizedBox(width: AppSpace.xxs),
        AppIconButton(
          icon: Icons.settings_rounded,
          tooltip: context.l10n.homeSettingsTooltip,
          size: 40,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            );
          },
        ),
        AppIconButton(
          icon: Icons.close_rounded,
          tooltip: context.l10n.close,
          size: 40,
          onPressed: onClose,
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.isConnected, required this.isConnecting, this.compact = false});

  final bool isConnected;
  final bool isConnecting;

  /// Only the dot, with the label for screen readers.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final color = isConnected
        ? p.success
        : isConnecting
        ? p.warning
        : p.danger;
    return StatusPill(
      color: color,
      busy: !isConnected && isConnecting,
      label: isConnected
          ? context.l10n.statusConnected
          : isConnecting
          ? context.l10n.homeConnecting
          : context.l10n.statusDisconnected,
    );
  }
}

/// Controls, touchpad and media tabs: a floating glass bar whose highlight
/// slides to the selected tab.
class RemoteBottomNav extends StatelessWidget {
  const RemoteBottomNav({
    super.key,
    required this.currentTab,
    required this.onTap,
  });

  final int currentTab;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final selected = currentTab.clamp(0, 2);
    final items = [
      (
        Icons.gamepad_rounded,
        Icons.gamepad_outlined,
        context.l10n.remoteTabControls,
      ),
      (
        Icons.touch_app_rounded,
        Icons.touch_app_outlined,
        context.l10n.remoteTabTouchpad,
      ),
      (
        Icons.queue_music_rounded,
        Icons.queue_music_outlined,
        context.l10n.remoteTabMedia,
      ),
    ];
    final duration = AppMotion.of(context, AppMotion.base);

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: AppSpace.sm),
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSpace.contentMaxWidth),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.md,
              AppSpace.xxs,
              AppSpace.md,
              0,
            ),
            // Opaque, not blurred: a backdrop filter would be redrawn on every
            // frame the touchpad animates.
            child: Container(
              height: 66,
              padding: const EdgeInsets.all(AppSpace.xs - 2),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [p.surfaceRaised, p.surface],
                ),
                borderRadius: AppRadius.all(AppRadius.xl),
                border: Border.all(color: p.glassBorder),
                boxShadow: AppShadows.raised(p),
              ),
              child: Stack(
                children: [
                  AnimatedAlign(
                    duration: duration,
                    curve: AppMotion.standard,
                    alignment: Alignment(-1 + selected.toDouble(), 0),
                    child: FractionallySizedBox(
                      widthFactor: 1 / 3,
                      heightFactor: 1,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: p.primaryText.withValues(
                            alpha: p.isDark ? 0.16 : 0.10,
                          ),
                          borderRadius: AppRadius.all(AppRadius.lg),
                        ),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      for (final (i, item) in items.indexed)
                        Expanded(
                          child: Pressable(
                            onTap: () => onTap(i),
                            selected: i == selected,
                            semanticLabel: item.$3,
                            pressedScale: 0.92,
                            borderRadius: AppRadius.all(AppRadius.lg),
                            child: _NavItem(
                              icon: i == selected ? item.$1 : item.$2,
                              label: item.$3,
                              selected: i == selected,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
  });

  final IconData icon;
  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final color = selected ? p.primaryText : p.textMuted;
    final duration = AppMotion.of(context, AppMotion.base);
    return ExcludeSemantics(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedScale(
            scale: selected ? 1.08 : 1,
            duration: duration,
            curve: AppMotion.standard,
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 3),
          AnimatedDefaultTextStyle(
            duration: duration,
            style: AppType.labelSmall.copyWith(
              color: color,
              fontSize: 11.5,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
            ),
            child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}
