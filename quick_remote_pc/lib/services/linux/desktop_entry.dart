import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

/// Installs a .desktop file and icon for the running build in the user's
/// data directory.
///
/// Wayland compositors (and GNOME's dock on X11) find a window's icon through
/// the .desktop file named after its app id; without one, KDE shows a generic
/// Wayland icon. A package that installs the files system-wide wins: then
/// nothing is written.
class DesktopEntry {
  static const appId = 'com.quickremote.quick_remote_pc';

  /// Marks files this class wrote, so it never replaces a user's own.
  static const _marker = 'X-QuickRemote-Generated=true';

  static Future<void> ensureInstalled() async {
    try {
      final home = Platform.environment['HOME'];
      if (home == null) return;
      final dataHome = Platform.environment['XDG_DATA_HOME'] ?? p.join(home, '.local', 'share');
      if (_installedSystemWide()) return;

      await _ensureIcon(dataHome);
      final desktopFile = File(p.join(dataHome, 'applications', '$appId.desktop'));
      // Rewritten when the build moved, so Exec starts the one running now.
      final content = render(Platform.resolvedExecutable);
      if (desktopFile.existsSync()) {
        final current = desktopFile.readAsStringSync();
        if (!current.contains(_marker) || current == content) return;
      }
      desktopFile.parent.createSync(recursive: true);
      desktopFile.writeAsStringSync(content);
      debugPrint('DesktopEntry: installed ${desktopFile.path}');
    } catch (e) {
      debugPrint('DesktopEntry: not installed: $e');
    }
  }

  static bool _installedSystemWide() {
    final dirs = (Platform.environment['XDG_DATA_DIRS'] ?? '/usr/local/share:/usr/share').split(':');
    return dirs.any((dir) => dir.isNotEmpty && File(p.join(dir, 'applications', '$appId.desktop')).existsSync());
  }

  static Future<void> _ensureIcon(String dataHome) async {
    // 512 px is the largest size the hicolor theme lists.
    final icon = File(p.join(dataHome, 'icons', 'hicolor', '512x512', 'apps', '$appId.png'));
    if (icon.existsSync()) return;
    final source = await rootBundle.load('assets/images/logo.png');
    final codec = await ui.instantiateImageCodec(source.buffer.asUint8List(), targetWidth: 512, targetHeight: 512);
    final frame = await codec.getNextFrame();
    final png = await frame.image.toByteData(format: ui.ImageByteFormat.png);
    frame.image.dispose();
    if (png == null) return;
    icon.parent.createSync(recursive: true);
    icon.writeAsBytesSync(png.buffer.asUint8List());
  }

  @visibleForTesting
  static String render(String executable) => '''[Desktop Entry]
Type=Application
Name=QuickRemote PC
Comment=Telefonla sunum ve bilgisayar kontrolü
Exec=${quoteExec(executable)}
Icon=$appId
Terminal=false
Categories=Office;Presentation;Utility;
StartupWMClass=$appId
$_marker
''';

  /// Quotes a path for the Exec key as the Desktop Entry spec asks: inside
  /// double quotes, `"`, `` ` ``, `$` and `\` take a backslash, and every
  /// backslash is doubled again because the value is a string.
  @visibleForTesting
  static String quoteExec(String path) {
    if (!RegExp(r'''[\s"'\\`$<>~|&;*?#()%=]''').hasMatch(path)) return path;
    final escaped = path.replaceAllMapped(RegExp(r'["`$\\]'), (m) => '\\${m[0]}');
    return '"${escaped.replaceAll(r'\', r'\\')}"';
  }
}
