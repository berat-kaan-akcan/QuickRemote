import 'package:flutter/material.dart';
import '../../../widgets/ui/ui.dart';

/// A block of the main window: the surface, a hairline edge, large corners.
class HomeCard extends StatelessWidget {
  const HomeCard({super.key, required this.child, this.padding = const EdgeInsets.all(AppSpace.md)});

  final Widget child;
  final EdgeInsetsGeometry padding;

  static const radius = 22.0;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: AppRadius.all(radius),
        border: Border.all(color: p.border),
      ),
      child: child,
    );
  }
}

/// The capitals over a group of rows.
class HomeSectionLabel extends StatelessWidget {
  const HomeSectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Text(
        text.toUpperCase(),
        style: AppType.overline.copyWith(color: context.palette.textMuted, fontSize: 11),
      ),
    );
  }
}
