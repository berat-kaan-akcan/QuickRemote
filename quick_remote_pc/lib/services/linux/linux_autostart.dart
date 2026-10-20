import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import '../desktop/autostart.dart';
import 'desktop_entry.dart';

/// The XDG autostart entry: `~/.config/autostart/<app id>.desktop`, starting
/// the app with `--minimized`. Only an entry this app wrote
/// ([DesktopEntry.marker]) is replaced or removed.
class LinuxAutostart implements Autostart {
  LinuxAutostart({String? configHome, String? executable})
    : _configHome = configHome,
      _executable = executable;

  final String? _configHome;
  final String? _executable;

  @visibleForTesting
  File? get file {
    final home = Platform.environment['HOME'];
    final config =
        _configHome ??
        Platform.environment['XDG_CONFIG_HOME'] ??
        (home == null ? null : p.join(home, '.config'));
    if (config == null) return null;
    return File(p.join(config, 'autostart', '${DesktopEntry.appId}.desktop'));
  }

  String get _content => DesktopEntry.render(
    _executable ?? Platform.resolvedExecutable,
    autostart: true,
  );

  @override
  Future<bool> isEnabled() async {
    final file = this.file;
    if (file == null || !file.existsSync()) return false;
    try {
      return isEnabledEntry(file.readAsStringSync());
    } catch (_) {
      return false;
    }
  }

  /// A desktop that turns an entry off writes `Hidden=true` (or GNOME's
  /// `X-GNOME-Autostart-enabled=false`) into it instead of deleting it.
  @visibleForTesting
  static bool isEnabledEntry(String content) {
    final lines = content.split('\n').map((l) => l.trim());
    return !lines.contains('Hidden=true') &&
        !lines.contains('X-GNOME-Autostart-enabled=false');
  }

  @override
  Future<bool> setEnabled(bool enabled) async {
    final file = this.file;
    if (file == null) return false;
    try {
      if (enabled) {
        if (file.existsSync() &&
            !file.readAsStringSync().contains(DesktopEntry.marker)) {
          // The user's own entry: it stays, and it already starts the app.
          return await isEnabled();
        }
        file.parent.createSync(recursive: true);
        file.writeAsStringSync(_content);
      } else if (file.existsSync()) {
        if (!file.readAsStringSync().contains(DesktopEntry.marker)) {
          return false;
        }
        file.deleteSync();
      }
      return true;
    } catch (e) {
      debugPrint('LinuxAutostart: $e');
      return false;
    }
  }

  @override
  Future<void> refresh() async {
    final file = this.file;
    if (file == null || !file.existsSync()) return;
    try {
      final current = file.readAsStringSync();
      if (!current.contains(DesktopEntry.marker) || !isEnabledEntry(current)) {
        return;
      }
      if (current != _content) file.writeAsStringSync(_content);
    } catch (e) {
      debugPrint('LinuxAutostart: $e');
    }
  }
}
