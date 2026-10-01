import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import '../input/linux/impress_bridge.dart';
import '../input/linux/uinput_device.dart';

enum ImpressStatus {
  /// Bridge is connected to a running LibreOffice.
  connected,

  /// LibreOffice is closed but will accept connections when opened.
  readyWhenOpened,

  /// LibreOffice is closed and not configured to accept connections.
  notConfigured,

  /// LibreOffice is closed and its profile still has the unauthenticated
  /// localhost TCP listener written by older versions.
  legacyListener,

  /// LibreOffice is running without the UNO listener.
  runningNotListening,

  /// LibreOffice is not installed.
  notInstalled,

  /// python3 or LibreOffice's Python-UNO bridge is missing.
  noUno,
}

/// One-time system setup the Linux server needs, and checks for it.
class LinuxSetup {
  static const _udevRule =
      'KERNEL=="uinput", SUBSYSTEM=="misc", TAG+="uaccess", OPTIONS+="static_node=uinput"';

  static bool get uinputAccessible => UinputDevice.hasAccess();

  /// Installs a udev rule granting the logged-in user access to /dev/uinput
  /// (asks for the admin password through polkit).
  static Future<bool> installUinputRule() async {
    const script = '''
set -e
echo '$_udevRule' > /etc/udev/rules.d/70-quickremote-uinput.rules
echo uinput > /etc/modules-load.d/quickremote-uinput.conf
modprobe uinput
udevadm control --reload-rules
udevadm trigger --action=change --sysname-match=uinput
udevadm settle
''';
    try {
      final result = await Process.run('pkexec', ['sh', '-c', script]);
      if (result.exitCode != 0) debugPrint('uinput rule install failed: ${result.stderr}');
      return result.exitCode == 0;
    } catch (e) {
      debugPrint('pkexec not available: $e');
      return false;
    }
  }

  // ── LibreOffice Impress ──

  static Future<bool> _succeeds(String exe, List<String> args) async {
    try {
      return (await Process.run(exe, args)).exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> _libreOfficeRunning() => _succeeds('pgrep', ['-x', 'soffice.bin']);

  static Future<bool> _libreOfficeInstalled() => _succeeds('sh', ['-c', 'command -v soffice']);

  static File get _registryFile {
    final configHome = Platform.environment['XDG_CONFIG_HOME'] ??
        p.join(Platform.environment['HOME'] ?? '', '.config');
    return File(p.join(configHome, 'libreoffice', '4', 'user', 'registrymodifications.xcu'));
  }

  static String get _registryItem =>
      '<item oor:path="/org.openoffice.Setup/Office">'
      '<prop oor:name="ooSetupConnectionURL" oor:op="fuse">'
      '<value>${ImpressBridge.acceptString}</value></prop></item>';

  static final _existingItem = RegExp(
    r'<item oor:path="/org\.openoffice\.Setup/Office"><prop oor:name="ooSetupConnectionURL".*?</item>',
    dotAll: true,
  );

  static ImpressStatus _registryStatus() {
    final file = _registryFile;
    if (!file.existsSync()) return ImpressStatus.notConfigured;
    return registryStatusOf(file.readAsStringSync());
  }

  /// Which connection URL a LibreOffice profile (registrymodifications.xcu) sets.
  @visibleForTesting
  static ImpressStatus registryStatusOf(String xcu) {
    final item = _existingItem.firstMatch(xcu)?.group(0);
    if (item == null) return ImpressStatus.notConfigured;
    if (item.contains(ImpressBridge.acceptString)) return ImpressStatus.readyWhenOpened;
    if (item.contains('socket,')) return ImpressStatus.legacyListener;
    return ImpressStatus.notConfigured;
  }

  /// Adds (or replaces) the ooSetupConnectionURL entry in LibreOffice's user
  /// profile, so every LibreOffice start listens on the user-only UNO pipe.
  /// Replacing also removes the legacy TCP listener of older versions.
  /// Must only run while LibreOffice is closed — it rewrites the file on exit.
  @visibleForTesting
  static String applyRegistryItem(String? xcu, String item) {
    if (xcu == null || !xcu.contains('</oor:items>')) {
      return '<?xml version="1.0" encoding="UTF-8"?>\n'
          '<oor:items xmlns:oor="http://openoffice.org/2001/registry" '
          'xmlns:xs="http://www.w3.org/2001/XMLSchema" '
          'xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">\n'
          '$item\n</oor:items>\n';
    }
    if (_existingItem.hasMatch(xcu)) return xcu.replaceFirst(_existingItem, item);
    return xcu.replaceFirst('</oor:items>', '$item\n</oor:items>');
  }

  static Future<ImpressStatus> impressStatus() async {
    final ping = await ImpressBridge.instance.request('ping');
    if (ping['ok'] == true && ping['connected'] == true) return ImpressStatus.connected;
    if (ping['error'] == 'NO_UNO' || ping['error'] == 'NO_PYTHON') {
      return await _libreOfficeInstalled() ? ImpressStatus.noUno : ImpressStatus.notInstalled;
    }
    if (await _libreOfficeRunning()) return ImpressStatus.runningNotListening;
    if (!await _libreOfficeInstalled()) return ImpressStatus.notInstalled;
    return _registryStatus();
  }

  /// Makes LibreOffice accept the bridge: permanently through the profile when
  /// it is closed, or immediately via `soffice --accept` when it is running.
  static Future<bool> enableImpressConnection() async {
    if (await _libreOfficeRunning()) {
      try {
        await Process.start('soffice', ['--accept=${ImpressBridge.acceptString}'],
            mode: ProcessStartMode.detached);
        return true;
      } catch (e) {
        debugPrint('soffice --accept failed: $e');
        return false;
      }
    }
    try {
      final file = _registryFile;
      final current = file.existsSync() ? file.readAsStringSync() : null;
      if (current != null) {
        // copy() keeps the profile's owner-only mode; writeAsString would
        // create the backup world-readable. It only applies to a new file.
        final backup = File('${file.path}.quickremote.bak');
        if (backup.existsSync()) await backup.delete();
        await file.copy(backup.path);
      } else {
        await file.parent.create(recursive: true);
      }
      await file.writeAsString(applyRegistryItem(current, _registryItem));
      return true;
    } catch (e) {
      debugPrint('Could not update LibreOffice profile: $e');
      return false;
    }
  }
}
