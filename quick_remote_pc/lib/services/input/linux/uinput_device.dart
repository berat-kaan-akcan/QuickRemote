import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'evdev_keys.dart';

typedef _OpenC = Int32 Function(Pointer<Utf8>, Int32);
typedef _OpenD = int Function(Pointer<Utf8>, int);
typedef _IoctlIntC = Int32 Function(Int32, UnsignedLong, VarArgs<(Int32,)>);
typedef _IoctlIntD = int Function(int, int, int);
typedef _IoctlPtrC = Int32 Function(Int32, UnsignedLong, VarArgs<(Pointer<Uint8>,)>);
typedef _IoctlPtrD = int Function(int, int, Pointer<Uint8>);
typedef _WriteC = IntPtr Function(Int32, Pointer<Uint8>, Size);
typedef _WriteD = int Function(int, Pointer<Uint8>, int);
typedef _CloseC = Int32 Function(Int32);
typedef _CloseD = int Function(int);
typedef _AccessC = Int32 Function(Pointer<Utf8>, Int32);
typedef _AccessD = int Function(Pointer<Utf8>, int);

/// A virtual input device created through /dev/uinput.
///
/// Works on X11 and every Wayland compositor because events enter the kernel
/// input stack like a real device. Requires write access to /dev/uinput
/// (see LinuxSetup.installUinputRule).
class UinputDevice {
  UinputDevice._(this._name, this._product, {required bool absolute}) : _absolute = absolute;

  /// Keyboard + relative mouse.
  static final UinputDevice instance = UinputDevice._('QuickRemote Virtual Input', 0x5152, absolute: false);

  /// Pointer that jumps to a position on the desktop, like the absolute
  /// mouse of a virtual machine. A separate device: libinput does not take
  /// absolute motion from a device that also has relative axes.
  static final UinputDevice pointer = UinputDevice._('QuickRemote Virtual Pointer', 0x5153, absolute: true);

  final String _name;
  final int _product;
  final bool _absolute;

  /// Range of the absolute axes; the compositor scales it to the desktop.
  static const absMax = 65535;

  static const _path = '/dev/uinput';
  static const _oWronly = 1;
  static const _oNonblock = 0x800;
  static const _wOk = 2;

  // ioctl request numbers (asm-generic encoding: dir<<30 | size<<16 | 'U'<<8 | nr)
  static const _uiDevCreate = 0x5501;
  static const _uiDevDestroy = 0x5502;
  static const _uiDevSetup = 0x405C5503; // _IOW('U', 3, struct uinput_setup) — 92 bytes
  static const _uiSetEvBit = 0x40045564;
  static const _uiSetKeyBit = 0x40045565;
  static const _uiSetRelBit = 0x40045566;
  static const _uiSetAbsBit = 0x40045567;
  static const _uiAbsSetup = 0x401C5504; // _IOW('U', 4, struct uinput_abs_setup) — 28 bytes

  static final DynamicLibrary _libc = DynamicLibrary.process();
  static final _open = _libc.lookupFunction<_OpenC, _OpenD>('open');
  static final _ioctlInt = _libc.lookupFunction<_IoctlIntC, _IoctlIntD>('ioctl');
  static final _ioctlPtr = _libc.lookupFunction<_IoctlPtrC, _IoctlPtrD>('ioctl');
  static final _write = _libc.lookupFunction<_WriteC, _WriteD>('write');
  static final _close = _libc.lookupFunction<_CloseC, _CloseD>('close');
  static final _access = _libc.lookupFunction<_AccessC, _AccessD>('access');

  /// struct input_event: struct timeval (2 longs) + u16 type + u16 code + s32 value.
  static final int _eventSize = sizeOf<Long>() * 2 + 8;

  int _fd = -1;
  DateTime? _lastAttempt;

  bool get isOpen => _fd >= 0;

  /// Whether the current user may open /dev/uinput for writing.
  static bool hasAccess() {
    final path = _path.toNativeUtf8();
    try {
      return _access(path, _wOk) == 0;
    } finally {
      malloc.free(path);
    }
  }

  /// Creates the virtual device if needed. Retries at most every 2 seconds so
  /// a later permission fix is picked up without restarting the app.
  bool ensureOpen() {
    if (_fd >= 0) return true;
    final now = DateTime.now();
    if (_lastAttempt != null && now.difference(_lastAttempt!) < const Duration(seconds: 2)) {
      return false;
    }
    _lastAttempt = now;

    final path = _path.toNativeUtf8();
    final fd = _open(path, _oWronly | _oNonblock);
    malloc.free(path);
    if (fd < 0) {
      debugPrint('uinput: cannot open $_path (permission missing?)');
      return false;
    }

    final setup = calloc<Uint8>(92);
    try {
      _ioctlInt(fd, _uiSetEvBit, Evdev.evKey);
      _ioctlInt(fd, _uiSetEvBit, Evdev.evSyn);
      if (_absolute) {
        // udev counts absolute axes plus a mouse button as a mouse.
        _ioctlInt(fd, _uiSetKeyBit, Evdev.btnLeft);
        _ioctlInt(fd, _uiSetEvBit, Evdev.evAbs);
        for (final axis in const [Evdev.absX, Evdev.absY]) {
          _ioctlInt(fd, _uiSetAbsBit, axis);
          if (!_setupAxis(fd, axis)) {
            debugPrint('uinput: absolute axis setup failed');
            _close(fd);
            return false;
          }
        }
      } else {
        _ioctlInt(fd, _uiSetEvBit, Evdev.evRel);
        for (final key in Evdev.allKeys.toSet()) {
          _ioctlInt(fd, _uiSetKeyBit, key);
        }
        _ioctlInt(fd, _uiSetRelBit, Evdev.relX);
        _ioctlInt(fd, _uiSetRelBit, Evdev.relY);
      }

      // struct uinput_setup { input_id{bustype,vendor,product,version}; char name[80]; u32 ff_effects_max; }
      final view = ByteData.sublistView(setup.asTypedList(92));
      view.setUint16(0, 0x03, Endian.host); // BUS_USB
      view.setUint16(2, 0x1d6b, Endian.host);
      view.setUint16(4, _product, Endian.host);
      view.setUint16(6, 1, Endian.host);
      final name = _name.codeUnits;
      for (var i = 0; i < name.length; i++) {
        setup[8 + i] = name[i];
      }

      if (_ioctlPtr(fd, _uiDevSetup, setup) < 0 || _ioctlInt(fd, _uiDevCreate, 0) < 0) {
        debugPrint('uinput: device setup failed');
        _close(fd);
        return false;
      }
    } finally {
      calloc.free(setup);
    }

    _fd = fd;
    debugPrint('uinput: $_name created');
    return true;
  }

  /// struct uinput_abs_setup { u16 code; struct input_absinfo { s32 value,
  /// minimum, maximum, fuzz, flat, resolution; } } — 2 bytes padding after code.
  static bool _setupAxis(int fd, int axis) {
    final buf = calloc<Uint8>(28);
    try {
      final view = ByteData.sublistView(buf.asTypedList(28));
      view.setUint16(0, axis, Endian.host);
      view.setInt32(12, absMax, Endian.host);
      return _ioctlPtr(fd, _uiAbsSetup, buf) >= 0;
    } finally {
      calloc.free(buf);
    }
  }

  void close() {
    if (_fd < 0) return;
    _ioctlInt(_fd, _uiDevDestroy, 0);
    _close(_fd);
    _fd = -1;
  }

  void _emit(List<(int, int, int)> events) {
    if (!ensureOpen()) return;
    final size = _eventSize * events.length;
    final buf = calloc<Uint8>(size);
    try {
      final data = ByteData.sublistView(buf.asTypedList(size));
      for (var i = 0; i < events.length; i++) {
        final base = i * _eventSize + _eventSize - 8;
        final (type, code, value) = events[i];
        data.setUint16(base, type, Endian.host);
        data.setUint16(base + 2, code, Endian.host);
        data.setInt32(base + 4, value, Endian.host);
      }
      if (_write(_fd, buf, size) < 0) {
        debugPrint('uinput: write failed, recreating device');
        _close(_fd);
        _fd = -1;
        _lastAttempt = null;
      }
    } finally {
      calloc.free(buf);
    }
  }

  static const _syn = (Evdev.evSyn, Evdev.synReport, 0);

  /// Presses and releases a single key.
  void tap(int code) => combo([code]);

  /// Presses all [codes] in order, then releases them in reverse order.
  void combo(List<int> codes) {
    _emit([
      for (final c in codes) (Evdev.evKey, c, 1),
      _syn,
      for (final c in codes.reversed) (Evdev.evKey, c, 0),
      _syn,
    ]);
  }

  void button(int code, {required bool down}) {
    _emit([(Evdev.evKey, code, down ? 1 : 0), _syn]);
  }

  void click(int code) {
    _emit([(Evdev.evKey, code, 1), _syn, (Evdev.evKey, code, 0), _syn]);
  }

  /// Moves the cursor of an absolute device to ([fx], [fy]), fractions of
  /// the desktop's width and height.
  void moveAbsolute(double fx, double fy) {
    assert(_absolute);
    _emit([
      (Evdev.evAbs, Evdev.absX, (fx.clamp(0.0, 1.0) * absMax).round()),
      (Evdev.evAbs, Evdev.absY, (fy.clamp(0.0, 1.0) * absMax).round()),
      _syn,
    ]);
  }

  void moveRelative(int dx, int dy) {
    _emit([
      if (dx != 0) (Evdev.evRel, Evdev.relX, dx),
      if (dy != 0) (Evdev.evRel, Evdev.relY, dy),
      _syn,
    ]);
  }
}
