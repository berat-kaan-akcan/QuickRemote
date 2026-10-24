import 'package:quick_remote_shared/quick_remote_shared.dart';

import '../../../models/draw_tool.dart';
import '../../../providers/settings_provider.dart';
import '../../../services/websocket_service.dart';

/// What the phone can tell about the slideshow from what the PC sends, for
/// the differences between programs (destek-tablosu: the phone-only ones).
///
/// A PC that sends `caps` says which tools work ([caps]); for an older one
/// the phone guesses from `presenter`, `platform` and `current: 0`.
class ShowInfo {
  ShowInfo.of(WebSocketService ws)
    : caps = ws.presenterCaps,
      _overlay = ws.toolsAnywhere,
      _zoom = ws.zoomAvailable,
      running = ws.isPptRunning,
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

  /// The PC's word on what is in front and what works; null from an older PC.
  final PresenterCaps? caps;
  final bool _overlay;
  final bool _zoom;

  /// What is in front on the PC (a [FrontWindow] value); null when unknown.
  String? get front => caps?.front;

  /// A PDF viewer or a browser is in front and no show runs: only page turns
  /// and full screen work (START puts the viewer in full screen).
  bool get viewer => !running && FrontWindow.isViewer(front);

  bool _can(String cap, bool guess) => caps == null ? guess : caps!.has(cap);

  /// Without a show only the PC's overlay draws the tools.
  bool get _toolsGuess => running || _overlay;

  /// Whether [tool] works now.
  bool tool(DrawTool tool) => _can(switch (tool) {
        DrawTool.laser => RemoteCaps.laser,
        DrawTool.pen => RemoteCaps.pen,
        DrawTool.highlighter => RemoteCaps.highlighter,
        DrawTool.eraser => RemoteCaps.eraser,
      }, _toolsGuess);

  /// The drawing tools that work now.
  Set<DrawTool> get tools => {for (final t in DrawTool.values) if (tool(t)) t};

  bool get eraseAll => _can(RemoteCaps.eraseAll, _toolsGuess);

  /// Black and white screen (the overlay covers the screen outside a show).
  bool get blank => _can(RemoteCaps.blank, running || _overlay);

  /// Play and pause the slide's media.
  bool get media => _can(RemoteCaps.media, running);
  bool get rewind => _can(RemoteCaps.rewind, !windowsWps);

  bool get colorsAvailable => _can(RemoteCaps.colors, !userWps);

  /// Jump to a slide; never with a viewer in front, which has no slides.
  bool get canJump => !viewer && _can(RemoteCaps.goto, !userWps);

  bool get notes => _can(RemoteCaps.notes, true);
  bool get previews => _can(RemoteCaps.previews, true);

  /// The overlay's laser styles and taking back a stroke.
  bool get spotlight => _can(RemoteCaps.spotlight, _overlay);
  bool get zoom => _can(RemoteCaps.zoom, _overlay && _zoom);
  bool get undo => _can(RemoteCaps.undo, _overlay);

  /// A WPS the user started can move to the WPS the PC drives
  /// (WPS_TAKE_OVER); only a PC that says so.
  bool get takeOver => caps?.has(RemoteCaps.takeOver) ?? false;
}

/// The program the remote names: the one running the show, else the one the
/// user marked for this PC in the program sheet, else the PC's first.
String remoteProgram(WebSocketService ws, SettingsProvider settings) {
  if (ws.isPptRunning) return ws.presenter;
  final marked = settings.presenterFor(ws.serverAddress);
  if (marked != null && ws.presenters.contains(marked)) return marked;
  return ws.presenters.isNotEmpty ? ws.presenters.first : ws.presenter;
}
