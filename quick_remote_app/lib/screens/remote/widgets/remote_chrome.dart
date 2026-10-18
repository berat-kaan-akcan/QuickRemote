import 'package:flutter/material.dart';

import '../../settings/settings_screen.dart';
import '../../../l10n/app_language.dart';
import '../../../widgets/ui/ui.dart';

/// The app bar row of the Wi-Fi and Bluetooth remotes: logo, the PC and
/// program line, status chip, settings and close.
class RemoteHeader extends StatelessWidget {
  const RemoteHeader({
    super.key,
    required this.subtitle,
    required this.isConnected,
    required this.onClose,
    this.isConnecting = false,
    this.onReconnect,
    this.onSubtitleTap,
    this.subtitleColor,
    this.connectedColor,
    this.showStatus = true,
  });

  final Widget subtitle;
  final bool isConnected;
  final bool isConnecting;

  /// Shows a reconnect button when set.
  final VoidCallback? onReconnect;
  final VoidCallback onClose;

  /// Makes the subtitle a button with an arrow: the program sheet.
  final VoidCallback? onSubtitleTap;

  /// The subtitle's color (Bluetooth's light blue); muted text by default.
  final Color? subtitleColor;

  /// The status dot while connected; the success color by default.
  final Color? connectedColor;
  final bool showStatus;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final lineColor = subtitleColor ?? p.textMuted;
    final line = DefaultTextStyle.merge(
      style: AppType.bodySmall.copyWith(
        color: lineColor,
        fontSize: 11.5,
        fontWeight: FontWeight.w500,
        height: 1.25,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      child: IconTheme.merge(
        data: IconThemeData(color: lineColor, size: 15),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(child: subtitle),
            if (onSubtitleTap != null) const Icon(Icons.expand_more_rounded),
          ],
        ),
      ),
    );
    return Row(
      children: [
        const BrandTile(size: 36, shadow: false),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const BrandWordmark(fontSize: 16),
              const SizedBox(height: 2),
              if (onSubtitleTap == null)
                line
              else
                Pressable(
                  onTap: onSubtitleTap,
                  semanticLabel: context.l10n.remoteProgramHint,
                  pressedScale: 0.97,
                  borderRadius: AppRadius.all(AppRadius.xs),
                  child: line,
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
        if (showStatus)
          _StatusChip(
            isConnected: isConnected,
            isConnecting: isConnecting,
            connectedColor: connectedColor ?? p.success,
          ),
        const SizedBox(width: AppSpace.xxs),
        AppIconButton(
          icon: Icons.settings_rounded,
          tooltip: context.l10n.homeSettingsTooltip,
          size: 34,
          iconSize: 21,
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
          size: 34,
          iconSize: 21,
          onPressed: onClose,
        ),
      ],
    );
  }
}

/// "Connected" on the surface with a status dot; tinted while it is not.
class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.isConnected, required this.isConnecting, required this.connectedColor});

  final bool isConnected;
  final bool isConnecting;
  final Color connectedColor;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final color = isConnected
        ? connectedColor
        : isConnecting
        ? p.warning
        : p.danger;
    final label = isConnected
        ? context.l10n.statusConnected
        : isConnecting
        ? context.l10n.homeConnecting
        : context.l10n.statusDisconnected;
    // On narrow phones only the dot, with the label for screen readers.
    final compact = MediaQuery.sizeOf(context).width < 340;
    return Semantics(
      label: label,
      liveRegion: true,
      child: ExcludeSemantics(
        child: AnimatedContainer(
          duration: AppMotion.of(context, AppMotion.base),
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 8 : 10,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: AppRadius.all(AppRadius.pill),
            border: Border.all(
              color: isConnected ? p.border : color.withValues(alpha: 0.45),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isConnected && isConnecting)
                SizedBox.square(
                  dimension: 10,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: color,
                  ),
                )
              else
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.25),
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                ),
              if (!compact) ...[
                const SizedBox(width: 7),
                Text(
                  label,
                  maxLines: 1,
                  style: AppType.labelSmall.copyWith(
                    color: isConnected ? p.textPrimary : color,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Controls, touchpad and media tabs: a bar along the bottom edge whose
/// selected icon sits in a tinted pill.
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

    return DecoratedBox(
      decoration: BoxDecoration(
        color: p.surface,
        border: Border(top: BorderSide(color: p.border)),
      ),
      child: SafeArea(
        top: false,
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppSpace.contentMaxWidth,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.xs,
                AppSpace.xs,
                AppSpace.xs,
                AppSpace.xxs,
              ),
              child: Row(
                children: [
                  for (final (i, item) in items.indexed)
                    Expanded(
                      child: Pressable(
                        onTap: () => onTap(i),
                        selected: i == selected,
                        semanticLabel: item.$3,
                        pressedScale: 0.92,
                        borderRadius: AppRadius.all(AppRadius.md),
                        child: _NavItem(
                          icon: i == selected ? item.$1 : item.$2,
                          label: item.$3,
                          selected: i == selected,
                        ),
                      ),
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
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpace.xxs),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: duration,
              curve: AppMotion.standard,
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: AppSpace.xxs,
              ),
              decoration: BoxDecoration(
                color: p.primary.withValues(alpha: selected ? 0.18 : 0),
                borderRadius: AppRadius.all(AppRadius.pill),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: duration,
              style: AppType.labelSmall.copyWith(color: color, fontSize: 11.5),
              child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }
}
