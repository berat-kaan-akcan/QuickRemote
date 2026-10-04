import 'package:flutter/material.dart';

import '../../theme/app_palette.dart';
import '../../theme/app_tokens.dart';

/// Shared shapes of dialogs and bottom sheets. Their colors come from the
/// theme (`dialogTheme`, `bottomSheetTheme`, [AppPalette]).
class AppPopupTheme {
  AppPopupTheme._();

  static const double dialogRadius = AppRadius.xl;
  static const double bottomSheetRadius = AppRadius.xl;
  static const double buttonRadius = AppRadius.md;
  static const double inputRadius = AppRadius.md;

  static const double handleWidth = 40;
  static const double handleHeight = 5;

  /// Widest a dialog or sheet grows on a tablet.
  static const double maxWidth = 460;

  /// A text field in the theme's style ([InputDecorationTheme]).
  static InputDecoration inputDecoration({
    required BuildContext context,
    String? hintText,
    String? labelText,
    String? helperText,
    Widget? prefixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      labelText: labelText,
      helperText: helperText,
      helperMaxLines: 2,
      prefixIcon: prefixIcon,
    );
  }

  /// The route transition of the app's dialogs: a fade with a slight scale.
  static Future<T?> showAppDialog<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    bool barrierDismissible = true,
  }) {
    final palette = context.palette;
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: palette.scrim,
      transitionDuration: AppMotion.of(context, AppMotion.base),
      pageBuilder: (ctx, _, _) => builder(ctx),
      transitionBuilder: (ctx, animation, _, child) {
        final curved = CurvedAnimation(parent: animation, curve: AppMotion.standard, reverseCurve: AppMotion.exit);
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.94, end: 1).animate(curved),
            child: child,
          ),
        );
      },
    );
  }
}
