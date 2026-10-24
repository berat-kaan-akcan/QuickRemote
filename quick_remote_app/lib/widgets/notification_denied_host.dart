import 'package:flutter/material.dart';

import '../l10n/app_language.dart';
import '../services/background_session.dart';

/// Tells the user once that the notification permission is off (Android 13+),
/// with a key to the system settings. Wraps the app; never blocks anything.
class NotificationDeniedHost extends StatefulWidget {
  const NotificationDeniedHost({super.key, required this.child});

  final Widget child;

  @override
  State<NotificationDeniedHost> createState() => _NotificationDeniedHostState();
}

class _NotificationDeniedHostState extends State<NotificationDeniedHost> {
  @override
  void initState() {
    super.initState();
    BackgroundSession.notificationDenied.addListener(_changed);
    WidgetsBinding.instance.addPostFrameCallback((_) => _changed());
  }

  @override
  void dispose() {
    BackgroundSession.notificationDenied.removeListener(_changed);
    super.dispose();
  }

  void _changed() {
    if (!mounted || !BackgroundSession.notificationDenied.value) return;
    BackgroundSession.notificationDenied.value = false; // told once
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    final l10n = context.l10n;
    messenger.showSnackBar(
      SnackBar(
        content: Text(l10n.notificationDeniedNote),
        duration: const Duration(seconds: 12),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: l10n.notificationDeniedAction,
          onPressed: () {
            BackgroundSession.openSettings();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
