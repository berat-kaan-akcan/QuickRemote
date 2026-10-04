import 'package:flutter/material.dart';

import '../../theme/app_palette.dart';
import '../../theme/app_tokens.dart';
import '../../theme/app_typography.dart';
import 'app_card.dart';

/// The label above a group of cards, with an optional count and action.
class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.count, this.trailing, this.icon});

  final String title;
  final int? count;
  final Widget? trailing;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      header: true,
      child: Padding(
        padding: const EdgeInsets.only(left: AppSpace.xxs, bottom: AppSpace.xs),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: p.textMuted),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(title, style: AppType.overline.copyWith(color: p.textSecondary)),
            ),
            if (count != null && count! > 0) ...[
              const SizedBox(width: AppSpace.xs),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: p.primaryText.withValues(alpha: 0.12),
                  borderRadius: AppRadius.all(AppRadius.pill),
                ),
                child: Text('$count', style: AppType.labelSmall.copyWith(color: p.primaryText, fontSize: 11)),
              ),
            ],
            const Spacer(),
            ?trailing,
          ],
        ),
      ),
    );
  }
}

/// A row card: icon badge, title, subtitle and a trailing widget (a chevron
/// when tappable and nothing else is given).
class AppListTile extends StatelessWidget {
  const AppListTile({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.iconColor,
    this.leading,
    this.trailing,
    this.onTap,
    this.onLongPress,
    this.monoSubtitle = false,
    this.tint,
    this.padding = const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: AppSpace.sm + 2),
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Color? iconColor;

  /// Replaces the icon badge.
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// Sets the subtitle as an address or code.
  final bool monoSubtitle;
  final Color? tint;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final lead = leading ?? (icon == null ? null : IconBadge(icon: icon!, color: iconColor ?? p.primaryText));
    final trail = trailing ??
        (onTap == null
            ? null
            : Icon(Icons.chevron_right_rounded, color: p.textMuted, size: 22));
    return AppCard(
      onTap: onTap,
      onLongPress: onLongPress,
      tint: tint,
      padding: padding,
      radius: AppRadius.lg,
      semanticLabel: subtitle == null ? title : '$title, $subtitle',
      child: Row(
        children: [
          if (lead != null) ...[lead, const SizedBox(width: AppSpace.md - 2)],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppType.titleSmall.copyWith(color: p.textPrimary),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle!,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: (monoSubtitle ? AppType.mono : AppType.bodySmall).copyWith(color: p.textSecondary),
                  ),
                ],
              ],
            ),
          ),
          if (trail != null) ...[const SizedBox(width: AppSpace.xs), trail],
        ],
      ),
    );
  }
}

/// A list tile with a switch; the whole row toggles it.
class AppSwitchTile extends StatelessWidget {
  const AppSwitchTile({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.icon,
    this.iconColor,
    this.flat = false,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Color? iconColor;
  final bool value;
  final ValueChanged<bool>? onChanged;

  /// Without its own card, for rows inside a card.
  final bool flat;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final row = Row(
      children: [
        if (icon != null) ...[
          IconBadge(icon: icon!, color: iconColor ?? p.primaryText),
          const SizedBox(width: AppSpace.md - 2),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: AppType.titleSmall.copyWith(color: p.textPrimary)),
              if (subtitle != null) ...[
                const SizedBox(height: 3),
                Text(subtitle!, style: AppType.bodySmall.copyWith(color: p.textSecondary)),
              ],
            ],
          ),
        ),
        const SizedBox(width: AppSpace.sm),
        Switch(value: value, onChanged: onChanged),
      ],
    );
    final toggle = onChanged == null ? null : () => onChanged!(!value);
    return MergeSemantics(
      child: flat
          ? InkWell(
              onTap: toggle,
              borderRadius: AppRadius.all(AppRadius.md),
              child: Padding(padding: const EdgeInsets.symmetric(vertical: AppSpace.sm), child: row),
            )
          : AppCard(
              onTap: toggle,
              padding: const EdgeInsets.fromLTRB(AppSpace.md, AppSpace.sm + 2, AppSpace.sm, AppSpace.sm + 2),
              child: row,
            ),
    );
  }
}
