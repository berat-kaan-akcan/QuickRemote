import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:win32/win32.dart';

import 'autostart.dart';
import 'desktop_policy.dart';

/// A value under `HKCU\Software\Microsoft\Windows\CurrentVersion\Run` that
/// starts the app with `--minimized`. Not for an MSIX build, which would
/// need a `windows.startupTask` in its manifest instead.
class WindowsAutostart implements Autostart {
  static const _runKey = r'Software\Microsoft\Windows\CurrentVersion\Run';
  static const _valueName = 'QuickRemotePC';

  /// The Run value for [executable]: the path quoted, as Windows splits an
  /// unquoted one at its first space.
  @visibleForTesting
  static String command(String executable) => '"$executable" $minimizedFlag';

  String get _command => command(Platform.resolvedExecutable);

  String? _read() => using((arena) {
    const capacity = 2048;
    final data = arena<Uint16>(capacity);
    final size = arena<Uint32>()..value = capacity * sizeOf<Uint16>();
    final result = RegGetValue(
      HKEY_CURRENT_USER,
      arena.pcwstr(_runKey),
      arena.pcwstr(_valueName),
      RRF_RT_REG_SZ,
      null,
      data.cast(),
      size,
    );
    if (result != ERROR_SUCCESS) return null;
    return data.cast<Utf16>().toDartString();
  });

  bool _write(String value) => using((arena) {
    final data = arena.pcwstr(value);
    final result = RegSetKeyValue(
      HKEY_CURRENT_USER,
      arena.pcwstr(_runKey),
      arena.pcwstr(_valueName),
      REG_SZ,
      data,
      (value.length + 1) * sizeOf<Uint16>(),
    );
    return result == ERROR_SUCCESS;
  });

  bool _delete() => using((arena) {
    final result = RegDeleteKeyValue(
      HKEY_CURRENT_USER,
      arena.pcwstr(_runKey),
      arena.pcwstr(_valueName),
    );
    return result == ERROR_SUCCESS || result == ERROR_FILE_NOT_FOUND;
  });

  @override
  Future<bool> isEnabled() async {
    try {
      return _read() != null;
    } catch (e) {
      debugPrint('WindowsAutostart: $e');
      return false;
    }
  }

  @override
  Future<bool> setEnabled(bool enabled) async {
    try {
      return enabled ? _write(_command) : _delete();
    } catch (e) {
      debugPrint('WindowsAutostart: $e');
      return false;
    }
  }

  @override
  Future<void> refresh() async {
    try {
      final current = _read();
      if (current != null && current != _command) _write(_command);
    } catch (e) {
      debugPrint('WindowsAutostart: $e');
    }
  }
}
