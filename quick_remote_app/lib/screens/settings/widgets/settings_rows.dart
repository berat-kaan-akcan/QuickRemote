import 'package:flutter/material.dart';

import '../../../widgets/ui/ui.dart';

/// The capitals over a group of settings.
class SettingsSectionLabel extends StatelessWidget {
  const SettingsSectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, AppSpace.sm, 2, AppSpace.xs),
      child: Semantics(
        header: true,
        child: Text(text.toUpperCase(), style: AppType.overline.copyWith(color: context.palette.textMuted)),
      ),
    );
  }
}

/// Settings in one card, a line between each.
class SettingsGroup extends StatelessWidget {
  const SettingsGroup({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    // Material, not a colored box: the rows draw their ink on it.
    return Material(
      color: p.surface,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.all(AppRadius.md),
        side: BorderSide(color: p.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, child) in children.indexed) ...[
            if (i > 0) Divider(height: 1, thickness: 1, color: p.border),
            child,
          ],
        ],
      ),
    );
  }
}

/// A setting: its badge, name and a line under it, with a switch or an arrow.
class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    this.icon,
    this.iconColor,
    required this.title,
    this.subtitle,
    this.onTap,
    this.value,
    this.onChanged,
    this.trailing,
    this.alignTop = false,
    this.inset = false,
  });

  final IconData? icon;
  final Color? iconColor;
  final String title;
  final String? subtitle;

  /// Opens something: an arrow on the right.
  final VoidCallback? onTap;

  /// A switch on the right when set.
  final bool? value;
  final ValueChanged<bool>? onChanged;

  /// Replaces the arrow.
  final Widget? trailing;

  /// Aligns the badge and switch with the title, for a long line under it.
  final bool alignTop;

  /// Without an icon, keeps the text in line with the rows that have one.
  final bool inset;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final toggle = value != null;
    final row = Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: alignTop ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            IconBadge(icon: icon!, color: iconColor ?? p.primaryText, size: 38),
            const SizedBox(width: AppSpace.sm),
          ] else if (inset)
            const SizedBox(width: 38 + AppSpace.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppType.titleSmall.copyWith(color: p.textPrimary, fontSize: 14.5)),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: AppType.bodySmall.copyWith(color: p.textSecondary, fontSize: 12)),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpace.xs),
          if (toggle)
            ExcludeSemantics(child: Switch(value: value!, onChanged: onChanged))
          else
            trailing ?? Icon(Icons.chevron_right_rounded, color: p.textMuted),
        ],
      ),
    );
    if (toggle) {
      return Semantics(
        toggled: value,
        label: title,
        child: InkWell(onTap: onChanged == null ? null : () => onChanged!(!value!), child: row),
      );
    }
    return InkWell(onTap: onTap, child: row);
  }
}

/// A choice in a sheet: a name, maybe a line under it, and a radio.
class RadioRow extends StatelessWidget {
  const RadioRow({super.key, required this.label, required this.selected, required this.onTap, this.leading});

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final radius = AppRadius.all(AppRadius.md);
    return Pressable(
      onTap: onTap,
      selected: selected,
      semanticLabel: label,
      pressedScale: 0.98,
      borderRadius: radius,
      child: AnimatedContainer(
        duration: AppMotion.of(context, AppMotion.base),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: AppSpace.sm),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: radius,
          border: Border.all(color: selected ? p.primaryBright : p.border, width: selected ? 2 : 1),
        ),
        child: ExcludeSemantics(
          child: Row(
            children: [
              if (leading != null) ...[leading!, const SizedBox(width: AppSpace.sm)],
              Expanded(child: Text(label, style: AppType.titleSmall.copyWith(color: p.textPrimary, fontSize: 14.5))),
              AnimatedContainer(
                duration: AppMotion.of(context, AppMotion.base),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: selected ? p.primaryBright : p.textMuted, width: selected ? 6 : 2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
