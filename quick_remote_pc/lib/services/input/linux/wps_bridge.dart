import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'script_bridge.dart';

/// Talks to WPS Presentation through assets/linux/wps_bridge.py, which uses
/// WPS's RPC interface (the pywpsrpc package, installed into a private venv
/// by the setup panel).
///
/// The RPC interface cannot attach to a WPS the user started, so the bridge
/// controls only the WPS it opened a presentation in ("open"). WPS the user
/// started is driven with key presses instead (LinuxInputService).
class WpsBridge extends ScriptBridge {
  WpsBridge._() : super('WpsBridge', 'wps_bridge.py');
  static final WpsBridge instance = WpsBridge._();

  /// Venv holding pywpsrpc. Its interpreter runs the bridge.
  static Future<Directory> venvDirectory() async =>
      Directory(p.join((await getApplicationSupportDirectory()).path, 'wps-rpc'));

  static Future<String> venvPython() async => p.join((await venvDirectory()).path, 'bin', 'python3');

  @override
  Future<String?> interpreter() async {
    final python = await venvPython();
    return File(python).existsSync() ? python : null;
  }

  @override
  String get missingError => 'NO_RPC';

  /// The bridge's process holds the only connection to the WPS it started:
  /// a restart would leave that WPS out of reach until it is closed.
  @override
  bool get restartOnTimeout => false;

  /// Opens [path] in the bridge's WPS, starting one when needed.
  Future<Map<String, dynamic>> open(String path) =>
      request('open', {'path': path}, const Duration(seconds: 40));
}
