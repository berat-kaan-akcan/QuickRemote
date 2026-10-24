import 'package:flutter/material.dart';

import '../../widgets/ui/ui.dart';

/// A page's top bar: a square back key on the surface and the title.
class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTopBar({super.key, required this.title, this.onBack, this.action});

  final String title;

  /// A key on the right, such as [AppTopBarAction].
  final Widget? action;

  /// Pops the page when null.
  final VoidCallback? onBack;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final radius = AppRadius.all(AppRadius.sm);
    final back = MaterialLocalizations.of(context).backButtonTooltip;
    return AppBar(
      automaticallyImplyLeading: false,
      toolbarHeight: 64,
      titleSpacing: AppSpace.page,
      title: Row(
        children: [
          Pressable(
            onTap: onBack ?? () => Navigator.of(context).maybePop(),
            semanticLabel: back,
            tooltip: back,
            pressedScale: 0.9,
            borderRadius: radius,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: p.surface,
                borderRadius: radius,
                border: Border.all(color: p.border),
              ),
              child: Icon(Icons.arrow_back_rounded, color: p.textPrimary),
            ),
          ),
          const SizedBox(width: AppSpace.sm),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppType.title.copyWith(color: p.textPrimary, fontSize: 20, fontWeight: FontWeight.w700),
            ),
          ),
          ?action,
        ],
      ),
    );
  }
}

/// A square key in the top bar, on the surface like the back key.
class AppTopBarAction extends StatelessWidget {
  const AppTopBarAction({super.key, required this.icon, required this.tooltip, required this.onTap});

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final radius = AppRadius.all(AppRadius.sm);
    return Pressable(
      onTap: onTap,
      semanticLabel: tooltip,
      tooltip: tooltip,
      pressedScale: 0.9,
      borderRadius: radius,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: radius,
          border: Border.all(color: p.border),
        ),
        child: Icon(icon, color: p.textPrimary),
      ),
    );
  }
}
