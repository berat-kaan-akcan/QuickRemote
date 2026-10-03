import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';

/// A top-level X11 window as the window manager lists it.
class X11Window {
  final int id;

  /// WM_CLASS instance and class names.
  final List<String> wmClass;
  final int? pid;
  final bool fullscreen;

  const X11Window(this.id, this.wmClass, {this.pid, this.fullscreen = false});

  bool hasClass(String name) => wmClass.contains(name);
}

/// Reads the window manager's view of X11 windows (EWMH) through XCB.
///
/// WPS runs on X11 (XWayland on Wayland sessions), so this finds its windows
/// on both. A Wayland application with the focus leaves `_NET_ACTIVE_WINDOW`
/// on a window without WM_CLASS. XCB rather than Xlib: Xlib's error handler
/// is process-wide (GTK installs its own), and a window that closes between
/// two requests raises an error.
class X11Windows {
  X11Windows._();
  static final X11Windows instance = X11Windows._();

  static DynamicLibrary? _lib;
  Pointer<Void>? _conn;
  int _root = 0;
  final Map<String, int> _atoms = {};

  bool _open() {
    final conn = _conn;
    if (conn != null) {
      if (_xcbHasError(conn) == 0) return true;
      _xcbDisconnect(conn);
      _conn = null;
      _atoms.clear();
    }
    try {
      _lib ??= DynamicLibrary.open('libxcb.so.1');
    } catch (e) {
      debugPrint('X11Windows: libxcb not available: $e');
      return false;
    }
    // DISPLAY unset (a pure Wayland session): no X11 windows to find.
    final newConn = _xcbConnect(nullptr, nullptr);
    if (newConn == nullptr) return false;
    if (_xcbHasError(newConn) != 0) {
      _xcbDisconnect(newConn);
      return false;
    }
    final screen = _xcbSetupRootsIterator(_xcbGetSetup(newConn)).data;
    if (screen == nullptr) {
      _xcbDisconnect(newConn);
      return false;
    }
    _root = screen.cast<Uint32>().value; // xcb_screen_t starts with its root window
    _conn = newConn;
    return true;
  }

  int _atom(String name) {
    final cached = _atoms[name];
    if (cached != null) return cached;
    final str = name.toNativeUtf8();
    try {
      final cookie = _xcbInternAtom(_conn!, 0, name.length, str);
      final reply = _xcbInternAtomReply(_conn!, cookie, nullptr);
      if (reply == nullptr) return 0;
      // xcb_intern_atom_reply_t: u8 type, u8 pad, u16 seq, u32 length, u32 atom
      final atom = reply.cast<Uint32>()[2];
      _free(reply);
      return _atoms[name] = atom;
    } finally {
      malloc.free(str);
    }
  }

  /// The raw value of [property] on [window], or null when it is not set.
  Uint8List? _property(int window, String property, {int type = 0, int maxBytes = 4096}) {
    final atom = _atom(property);
    if (atom == 0) return null;
    final cookie = _xcbGetProperty(_conn!, 0, window, atom, type, 0, maxBytes ~/ 4);
    final error = calloc<Pointer<Void>>();
    try {
      final reply = _xcbGetPropertyReply(_conn!, cookie, error);
      if (error.value != nullptr) _free(error.value);
      if (reply == nullptr) return null; // e.g. the window closed meanwhile
      try {
        final length = _xcbGetPropertyValueLength(reply);
        if (length <= 0) return null;
        return Uint8List.fromList(_xcbGetPropertyValue(reply).cast<Uint8>().asTypedList(length));
      } finally {
        _free(reply);
      }
    } finally {
      calloc.free(error);
    }
  }

  static List<int> _cardinals(Uint8List? data) {
    if (data == null) return const [];
    final view = ByteData.sublistView(data);
    return [for (var i = 0; i + 4 <= data.length; i += 4) view.getUint32(i, Endian.host)];
  }

  X11Window _window(int id) {
    final classBytes = _property(id, 'WM_CLASS');
    final wmClass = classBytes == null ? const <String>[] : parseWmClass(classBytes);
    final pid = _cardinals(_property(id, '_NET_WM_PID'));
    final states = _cardinals(_property(id, '_NET_WM_STATE'));
    return X11Window(
      id,
      wmClass,
      pid: pid.isEmpty ? null : pid.first,
      fullscreen: states.contains(_atom('_NET_WM_STATE_FULLSCREEN')),
    );
  }

  /// The X11 window with the keyboard focus, or null when it is not an X11
  /// window (or X11 is not reachable).
  X11Window? activeWindow() {
    try {
      if (!_open()) return null;
      final ids = _cardinals(_property(_root, '_NET_ACTIVE_WINDOW'));
      if (ids.isEmpty || ids.first == 0) return null;
      final window = _window(ids.first);
      return window.wmClass.isEmpty ? null : window;
    } catch (e) {
      debugPrint('X11Windows.activeWindow failed: $e');
      return null;
    }
  }

  /// The top-level windows the window manager manages.
  List<X11Window> clientWindows() {
    try {
      if (!_open()) return const [];
      final ids = _cardinals(_property(_root, '_NET_CLIENT_LIST', maxBytes: 64 * 1024));
      return [for (final id in ids) _window(id)];
    } catch (e) {
      debugPrint('X11Windows.clientWindows failed: $e');
      return const [];
    }
  }

  /// Splits WM_CLASS ("instance\0class\0") into its names.
  @visibleForTesting
  static List<String> parseWmClass(Uint8List bytes) => String.fromCharCodes(bytes)
      .split('\u0000')
      .where((part) => part.isNotEmpty)
      .toList();
}

// ── libxcb bindings ──

final class _ScreenIterator extends Struct {
  external Pointer<Void> data;
  @Int32()
  external int rem;
  @Int32()
  external int index;
}

final class _Cookie extends Struct {
  @Uint32()
  external int sequence;
}

DynamicLibrary get _xcb => X11Windows._lib!;
final _libc = DynamicLibrary.process();

final _xcbConnect = _xcb.lookupFunction<Pointer<Void> Function(Pointer<Utf8>, Pointer<Int32>),
    Pointer<Void> Function(Pointer<Utf8>, Pointer<Int32>)>('xcb_connect');
final _xcbDisconnect =
    _xcb.lookupFunction<Void Function(Pointer<Void>), void Function(Pointer<Void>)>('xcb_disconnect');
final _xcbHasError = _xcb.lookupFunction<Int32 Function(Pointer<Void>), int Function(Pointer<Void>)>(
    'xcb_connection_has_error');
final _xcbGetSetup = _xcb.lookupFunction<Pointer<Void> Function(Pointer<Void>),
    Pointer<Void> Function(Pointer<Void>)>('xcb_get_setup');
final _xcbSetupRootsIterator = _xcb.lookupFunction<_ScreenIterator Function(Pointer<Void>),
    _ScreenIterator Function(Pointer<Void>)>('xcb_setup_roots_iterator');
final _xcbInternAtom = _xcb.lookupFunction<_Cookie Function(Pointer<Void>, Uint8, Uint16, Pointer<Utf8>),
    _Cookie Function(Pointer<Void>, int, int, Pointer<Utf8>)>('xcb_intern_atom');
final _xcbInternAtomReply = _xcb.lookupFunction<
    Pointer<Void> Function(Pointer<Void>, _Cookie, Pointer<Pointer<Void>>),
    Pointer<Void> Function(Pointer<Void>, _Cookie, Pointer<Pointer<Void>>)>('xcb_intern_atom_reply');
final _xcbGetProperty = _xcb.lookupFunction<
    _Cookie Function(Pointer<Void>, Uint8, Uint32, Uint32, Uint32, Uint32, Uint32),
    _Cookie Function(Pointer<Void>, int, int, int, int, int, int)>('xcb_get_property');
final _xcbGetPropertyReply = _xcb.lookupFunction<
    Pointer<Void> Function(Pointer<Void>, _Cookie, Pointer<Pointer<Void>>),
    Pointer<Void> Function(Pointer<Void>, _Cookie, Pointer<Pointer<Void>>)>('xcb_get_property_reply');
final _xcbGetPropertyValue = _xcb.lookupFunction<Pointer<Void> Function(Pointer<Void>),
    Pointer<Void> Function(Pointer<Void>)>('xcb_get_property_value');
final _xcbGetPropertyValueLength = _xcb.lookupFunction<Int32 Function(Pointer<Void>),
    int Function(Pointer<Void>)>('xcb_get_property_value_length');
final _free = _libc.lookupFunction<Void Function(Pointer<Void>), void Function(Pointer<Void>)>('free');
