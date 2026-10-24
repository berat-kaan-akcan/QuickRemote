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
    this.minTarget = 48,
    this.keepChildSemantics = false,
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

  /// The least width and height of the touch area, drawn or not: a 44 px key
  /// still gets the 48 px Android asks for. The child keeps its own size. 0
  /// leaves the size to the child (a key that sits inside another).
  final double minTarget;

  /// With a [semanticLabel] the child's own text is left out of the
  /// accessibility tree, or a screen reader says everything twice ("Light,
  /// Light"). True for a child that holds buttons of its own.
  final bool keepChildSemantics;

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
                : Border.all(
                    color: palette.primaryText.withValues(alpha: 0),
                    width: 2,
                  ),
          ),
          // The tap action stays on the button; only the child's text goes.
          child: widget.semanticLabel != null && !widget.keepChildSemantics
              ? ExcludeSemantics(child: widget.child)
              : widget.child,
        ),
      ),
    );

    if (widget.minTarget > 0) {
      result = ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: widget.minTarget,
          minHeight: widget.minTarget,
        ),
        child: Align(widthFactor: 1, heightFactor: 1, child: result),
      );
    }

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
