import '../../linux/system_executable.dart';
import 'script_bridge.dart';

/// Talks to LibreOffice Impress through a persistent `python3` process running
/// assets/linux/impress_bridge.py (UNO) — the Linux counterpart of
/// PowerShellRunner + PowerPoint COM.
///
/// Lines carrying an `event` (replies, or unasked lines for laser positions):
/// `{"event": "cursor", "x", "y"}` asks to move the OS cursor to that
/// fraction of the desktop.
class ImpressBridge extends ScriptBridge {
  ImpressBridge._() : super('ImpressBridge', 'impress_bridge.py');
  static final ImpressBridge instance = ImpressBridge._();

  /// UNO pipe LibreOffice is asked to listen on: a Unix socket only the
  /// current user can connect to.
  static const pipeName = 'quickremote';
  static const acceptString = 'pipe,name=$pipeName;urp;';

  /// Written by older versions: an unauthenticated localhost TCP listener that
  /// any local user or sandboxed app with network access could drive.
  static const legacyAcceptString = 'socket,host=localhost,port=2002;urp;';

  @override
  Future<String?> interpreter() async => systemExecutable('python3');

  @override
  List<String> get scriptArguments => const [pipeName];
}
