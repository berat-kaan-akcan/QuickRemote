import 'package:flutter/material.dart';

import '../../theme/app_palette.dart';
import '../../theme/app_tokens.dart';

/// Makes [child] tappable with the app's press feedback: it shrinks a little
/// while held, dims when disabled, and shows a focus ring for keyboards.
///
/// Disabled when both [onTap] and [onLongPress] are null.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.pressedScale = 0.96,
    this.hoveredScale = 1.0,
    this.borderRadius = const BorderRadius.all(Radius.circular(AppRadius.md)),
    this.semanticLabel,
    this.tooltip,
    this.selected,
    this.dimWhenDisabled = true,
    this.behavior = HitTestBehavior.opaque,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// Scale while a finger is down; 1 turns the effect off.
  final double pressedScale;

  /// Scale under a mouse pointer (desktop); 1 by default.
  final double hoveredScale;

  /// Shape of the focus ring.
  final BorderRadius borderRadius;
  final String? semanticLabel;
  final String? tooltip;

  /// For toggles and segments: announced as selected.
  final bool? selected;

  /// Disabled widgets fade to 45 % unless they style themselves.
  final bool dimWhenDisabled;
  final HitTestBehavior behavior;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _pressed = false;
  bool _focused = false;
  bool _hovered = false;

  bool get _enabled => widget.onTap != null || widget.onLongPress != null;

  void _setPressed(bool value) {
    if (_pressed != value && mounted) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final fast = AppMotion.of(context, AppMotion.fast);

    Widget result = AnimatedScale(
      scale: _pressed
          ? widget.pressedScale
          : _hovered && _enabled
              ? widget.hoveredScale
              : 1,
      duration: fast,
      curve: AppMotion.press,
      child: AnimatedOpacity(
        opacity: !_enabled && widget.dimWhenDisabled ? 0.45 : 1,
        duration: AppMotion.of(context, AppMotion.base),
        child: DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius,
            border: _focused
                ? Border.all(color: palette.primaryText, width: 2)
                : Border.all(color: palette.primaryText.withValues(alpha: 0), width: 2),
          ),
          child: widget.child,
        ),
      ),
    );

    result = GestureDetector(
      behavior: widget.behavior,
      onTapDown: _enabled ? (_) => _setPressed(true) : null,
      onTapUp: _enabled ? (_) => _setPressed(false) : null,
      onTapCancel: _enabled ? () => _setPressed(false) : null,
      onTap: widget.onTap,
      onLongPress: widget.onLongPress == null
          ? null
          : () {
              _setPressed(false);
              widget.onLongPress!();
            },
      child: result,
    );

    result = FocusableActionDetector(
      enabled: _enabled,
      mouseCursor: _enabled ? SystemMouseCursors.click : MouseCursor.defer,
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            (widget.onTap ?? widget.onLongPress)?.call();
            return null;
          },
        ),
      },
      child: result,
    );

    result = Semantics(
      button: true,
      enabled: _enabled,
      selected: widget.selected,
      label: widget.semanticLabel,
      child: result,
    );

    if (widget.tooltip != null) {
      result = Tooltip(message: widget.tooltip!, child: result);
    }
    return result;
  }
}
