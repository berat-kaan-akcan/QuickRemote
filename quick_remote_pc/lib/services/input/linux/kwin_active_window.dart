import 'dart:async';
import 'dart:io';

import 'package:dbus/dbus.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// The focused window as KWin sees it: also a native Wayland window, which
/// X11 never sees (Firefox and Chrome run as such on KDE Wayland).
class KWinWindow {
  /// KWin's `resourceClass` and `resourceName`: the Wayland app_id
  /// ("firefox", "google-chrome", "org.kde.okular"), or an X11 window's
  /// WM_CLASS.
  final String resourceClass;
  final String resourceName;
  final bool fullscreen;

  /// KWin's `internalId`, the same for the window's whole life.
  final String id;

  const KWinWindow(this.resourceClass, this.resourceName, {this.fullscreen = false, this.id = ''});
}

/// Follows KWin's focused window on a KDE Wayland session.
///
/// KWin has no call that answers "which window is active". A small KWin
/// script is loaded through `org.kde.kwin.Scripting` instead; on every
/// activation and full-screen change it calls [_iface] `Update` on this
/// connection (KWin's `callDBus`), so [current] is always at hand without a
/// round trip. Only calls from KWin's own bus name are taken. Without KWin
/// (GNOME, X11 sessions, where X11 already tells) nothing is loaded and
/// [current] stays null.
class KWinActiveWindow {
  KWinActiveWindow._();

  static final KWinActiveWindow instance = KWinActiveWindow._();

  static const _kwin = 'org.kde.KWin';
  static const _pluginName = 'quickremote_active_window';
  static const _iface = 'com.quickremote.ActiveWindow';
  static final _path = DBusObjectPath('/com/quickremote/ActiveWindow');

  DBusClient? _client;
  String? _kwinOwner;
  StreamSubscription<DBusNameOwnerChangedEvent>? _kwinRestarts;

  /// The focused window, null while unknown.
  KWinWindow? current;

  /// Loads the script on a Wayland session with KWin; again when KWin
  /// restarts.
  Future<void> start() async {
    if (_client != null || !Platform.isLinux) return;
    if (Platform.environment['XDG_SESSION_TYPE'] != 'wayland') return;
    final client = DBusClient.session();
    _client = client;
    try {
      await client.registerObject(_Receiver(_path, _onUpdate, isKWin: (sender) => sender != null && sender == _kwinOwner));
      _kwinRestarts = client.nameOwnerChanged
          .where((e) => e.name == _kwin && e.newOwner != null)
          .listen((_) => _load(client));
      await _load(client);
    } catch (e) {
      debugPrint('KWinActiveWindow: not started: $e');
      await stop();
    }
  }

  Future<void> stop() async {
    await _kwinRestarts?.cancel();
    _kwinRestarts = null;
    final client = _client;
    _client = null;
    current = null;
    if (client == null) return;
    try {
      await _scripting(client).callMethod('org.kde.kwin.Scripting', 'unloadScript', [const DBusString(_pluginName)]);
    } catch (_) {}
    await client.close();
  }

  static DBusRemoteObject _scripting(DBusClient client) =>
      DBusRemoteObject(client, name: _kwin, path: DBusObjectPath('/Scripting'));

  Future<void> _load(DBusClient client) async {
    current = null;
    _kwinOwner = await client.getNameOwner(_kwin);
    if (_kwinOwner == null) {
      debugPrint('KWinActiveWindow: no KWin on the session bus');
      return;
    }
    final scripting = _scripting(client);
    try {
      // A copy left by an earlier run (or a crash) would call a dead name.
      await scripting.callMethod('org.kde.kwin.Scripting', 'unloadScript', [const DBusString(_pluginName)]);
      final dir = Directory(p.join((await getApplicationSupportDirectory()).path, 'kwin'));
      await dir.create(recursive: true);
      final file = File(p.join(dir.path, 'active_window.js'));
      await file.writeAsString(script(client.uniqueName));
      await scripting.callMethod(
        'org.kde.kwin.Scripting',
        'loadScript',
        [DBusString(file.path), const DBusString(_pluginName)],
        replySignature: DBusSignature('i'),
      );
      // Runs every loaded script that is not running yet: the same call on
      // KWin 5 and 6 (the script's own object path differs between them).
      await scripting.callMethod('org.kde.kwin.Scripting', 'start', const [], replySignature: DBusSignature(''));
      debugPrint('KWinActiveWindow: script loaded');
    } on DBusMethodResponseException catch (e) {
      debugPrint('KWinActiveWindow: loading the script failed: ${e.errorName}');
    }
  }

  void _onUpdate(KWinWindow? window) => current = window;

  /// The KWin script. It sends the active window's class, name, full-screen
  /// state and id to [service], on each activation and when the active
  /// window enters or leaves full screen. KWin 6 names it `activeWindow` /
  /// `windowActivated`, KWin 5 `activeClient` / `clientActivated`. Numbers
  /// are left out: callDBus would send JavaScript numbers as doubles.
  @visibleForTesting
  static String script(String service) => '''
var target = ${_jsString(service)};
var watched = null;
function send(w) {
  callDBus(target, "${_path.value}", "$_iface", "Update",
      w ? String(w.resourceClass || "") : "",
      w ? String(w.resourceName || "") : "",
      w ? !!w.fullScreen : false,
      w ? String(w.internalId) : "");
}
function fullScreenChanged() { send(watched); }
function activated(w) {
  if (watched) { try { watched.fullScreenChanged.disconnect(fullScreenChanged); } catch (e) {} }
  watched = w || null;
  if (watched) { try { watched.fullScreenChanged.connect(fullScreenChanged); } catch (e) {} }
  send(watched);
}
if (workspace.windowActivated) { workspace.windowActivated.connect(activated); }
else { workspace.clientActivated.connect(activated); }
activated(workspace.activeWindow !== undefined ? workspace.activeWindow : workspace.activeClient);
''';

  static String _jsString(String value) => '"${value.replaceAll(r'\', r'\\').replaceAll('"', r'\"')}"';

  /// The window an `Update` call's arguments name; null when none is active
  /// (an empty class and id).
  @visibleForTesting
  static KWinWindow? parseUpdate(List<DBusValue> values) {
    final [resourceClass, resourceName, fullscreen, id] = values;
    final window = KWinWindow(resourceClass.asString(), resourceName.asString(),
        fullscreen: fullscreen.asBoolean(), id: id.asString());
    return window.resourceClass.isEmpty && window.resourceName.isEmpty && window.id.isEmpty ? null : window;
  }
}

class _Receiver extends DBusObject {
  _Receiver(super.path, this._onUpdate, {required this.isKWin});

  final void Function(KWinWindow? window) _onUpdate;

  /// Whether a call comes from KWin. Any program on the session bus could
  /// call here and claim another window is in front.
  final bool Function(String? sender) isKWin;

  @override
  Future<DBusMethodResponse> handleMethodCall(DBusMethodCall methodCall) async {
    if (methodCall.interface != KWinActiveWindow._iface) return DBusMethodErrorResponse.unknownInterface();
    if (!isKWin(methodCall.sender)) return DBusMethodErrorResponse.accessDenied();
    if (methodCall.name != 'Update') return DBusMethodErrorResponse.unknownMethod();
    if (methodCall.signature != DBusSignature('ssbs')) return DBusMethodErrorResponse.invalidArgs();
    _onUpdate(KWinActiveWindow.parseUpdate(methodCall.values));
    return DBusMethodSuccessResponse();
  }
}
