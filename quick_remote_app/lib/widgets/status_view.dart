import 'package:flutter/material.dart';

import 'ui/ui.dart';

/// A state of a page in its middle: a large icon, a title and a line, with
/// the actions at the bottom (the Bluetooth connect screen's states, a
/// connection that failed).
class StatusView extends StatelessWidget {
  const StatusView({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
    this.neutral = false,
    this.actions = const [],
  });

  final IconData icon;
  final Color color;
  final String title;
  final String message;

  /// The icon on the plain surface, for states that are no one's fault.
  final bool neutral;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return CustomScrollView(
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: FadeSlideIn(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          color: neutral
                              ? p.surface
                              : color.withValues(alpha: 0.12),
                          borderRadius: AppRadius.all(AppRadius.xl),
                          border: neutral ? Border.all(color: p.border) : null,
                        ),
                        child: Icon(icon, color: color, size: 52),
                      ),
                      const SizedBox(height: AppSpace.md),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: AppType.headline.copyWith(
                          color: p.textPrimary,
                          fontSize: 23,
                        ),
                      ),
                      const SizedBox(height: AppSpace.md),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpace.xs,
                        ),
                        child: Text(
                          message,
                          textAlign: TextAlign.center,
                          style: AppType.body.copyWith(
                            color: p.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              for (final (i, action) in actions.indexed) ...[
                SizedBox(height: i == 0 ? AppSpace.md : AppSpace.sm),
                action,
              ],
              const SizedBox(height: AppSpace.md),
            ],
          ),
        ),
      ],
    );
  }
}
