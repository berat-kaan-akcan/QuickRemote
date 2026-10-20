import '../server/network_manager.dart';

/// The argument the autostart entries pass (Linux `~/.config/autostart`,
/// Windows' Run key): the app starts in the tray, its window hidden. The
/// runners read it too (`my_application.cc`, `main.cpp`).
const minimizedFlag = '--minimized';

/// Whether the app was started at login, its window hidden.
bool startedMinimized(List<String> args) => args.contains(minimizedFlag);

/// The window is shown at start unless the app was started minimized into a
/// tray: without a tray icon nothing could bring it back.
bool showWindowAtStart({required bool minimized, required bool trayShown}) =>
    !minimized || !trayShown;

/// What closing the window does.
enum CloseAction { hideToTray, quit }

/// The window goes to the tray only when there is one to bring it back from
/// (Linux: a StatusNotifierWatcher on the session bus) and Settings says so.
CloseAction closeAction({required bool trayShown, required bool closeToTray}) =>
    trayShown && closeToTray ? CloseAction.hideToTray : CloseAction.quit;

/// Whether the app starts the server by itself when it opens.
enum LaunchStart {
  /// Settings → "Start the server on launch" is off.
  off,
  start,

  /// The network is public: the server waits for the user (status amber).
  heldBack,
}

/// The server never starts by itself on a public network; the user starts
/// it there (and sees the public-network warning).
LaunchStart launchStart({
  required bool startServerOnLaunch,
  required NetworkTrust trust,
}) {
  if (!startServerOnLaunch) return LaunchStart.off;
  if (trust == NetworkTrust.untrusted) return LaunchStart.heldBack;
  return LaunchStart.start;
}

/// What the tray icon shows.
enum TrayStatus { off, on, connected, attention }

TrayStatus trayStatus({
  required bool running,
  required int clients,
  required bool heldBack,
}) {
  if (running) return clients > 0 ? TrayStatus.connected : TrayStatus.on;
  return heldBack ? TrayStatus.attention : TrayStatus.off;
}
