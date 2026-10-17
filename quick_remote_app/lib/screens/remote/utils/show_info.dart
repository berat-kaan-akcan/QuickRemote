import '../../../providers/settings_provider.dart';
import '../../../services/websocket_service.dart';

/// What the phone can tell about the slideshow from what the PC sends, for
/// the differences between programs (destek-tablosu: the phone-only ones).
class ShowInfo {
  ShowInfo.of(WebSocketService ws)
    : running = ws.isPptRunning,
      unreadable =
          ws.isPptRunning && ws.currentSlide == 0 && ws.totalSlides == 0,
      userWps =
          ws.isPptRunning &&
          ws.currentSlide == 0 &&
          ws.totalSlides == 0 &&
          ws.presenter == 'wps' &&
          ws.pcPlatform == 'linux',
      windowsWps =
          ws.isPptRunning &&
          ws.presenter == 'wps' &&
          ws.pcPlatform == 'windows';

  /// A slideshow runs. Without one the PC ignores the drawing tools, black
  /// and white screen and slide media.
  final bool running;

  /// A show the PC sees but cannot read: no slide number and no notes.
  final bool unreadable;

  /// A WPS on Linux that QuickRemote did not open: its keys work only while
  /// it is in front, it takes no colors, and jumps only start it.
  final bool userWps;

  /// WPS on Windows: no laser (the pointer arrow follows the phone), no
  /// rewind and no play state for slide media.
  final bool windowsWps;

  bool get colorsAvailable => !userWps;
  bool get canJump => !userWps;
}

/// The program the remote names: the one running the show, else the one the
/// user marked for this PC in the program sheet, else the PC's first.
String remoteProgram(WebSocketService ws, SettingsProvider settings) {
  if (ws.isPptRunning) return ws.presenter;
  final marked = settings.presenterFor(ws.serverAddress);
  if (marked != null && ws.presenters.contains(marked)) return marked;
  return ws.presenters.isNotEmpty ? ws.presenters.first : ws.presenter;
}
