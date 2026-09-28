import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Talks to LibreOffice Impress through a persistent `python3` process running
/// assets/linux/impress_bridge.py (UNO). One JSON request/reply per line,
/// matched by `id` — the Linux counterpart of PowerShellRunner + PowerPoint COM.
class ImpressBridge {
  ImpressBridge._();
  static final ImpressBridge instance = ImpressBridge._();

  /// UNO port LibreOffice is asked to listen on (localhost only).
  static const port = 2002;
  static const acceptString = 'socket,host=localhost,port=$port;urp;';

  /// Overridable in tests to run the bridge from the source tree.
  @visibleForTesting
  static String? scriptPathOverride;

  Process? _process;
  Future<Process?>? _starting;
  int _nextId = 1;
  final Map<int, Completer<Map<String, dynamic>>> _pending = {};

  Future<String> _scriptPath() async {
    if (scriptPathOverride != null) return scriptPathOverride!;
    final source = await rootBundle.loadString('assets/linux/impress_bridge.py');
    final dir = await getApplicationSupportDirectory();
    final file = File(p.join(dir.path, 'impress_bridge.py'));
    if (!file.existsSync() || file.readAsStringSync() != source) {
      await file.writeAsString(source);
    }
    return file.path;
  }

  Future<Process?> _ensureProcess() {
    if (_process != null) return Future.value(_process);
    return _starting ??= _start().whenComplete(() => _starting = null);
  }

  Future<Process?> _start() async {
    try {
      final process = await Process.start('python3', ['-u', await _scriptPath(), '$port']);
      process.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(_onLine);
      process.stderr
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) => debugPrint('ImpressBridge stderr: $line'));
      process.exitCode.then((code) {
        debugPrint('ImpressBridge exited with code $code');
        if (identical(_process, process)) _reset();
      });
      _process = process;
      return process;
    } catch (e) {
      debugPrint('ImpressBridge: failed to start python3: $e');
      return null;
    }
  }

  void _onLine(String line) {
    try {
      final reply = jsonDecode(line) as Map<String, dynamic>;
      _pending.remove(reply['id'])?.complete(reply);
    } catch (e) {
      debugPrint('ImpressBridge: bad reply "$line": $e');
    }
  }

  void _reset() {
    _process?.kill();
    _process = null;
    for (final c in _pending.values) {
      if (!c.isCompleted) c.complete({'ok': false, 'error': 'BRIDGE_DIED'});
    }
    _pending.clear();
  }

  /// Sends [cmd] and waits for the reply. Never throws: failures come back as
  /// `{'ok': false, 'error': ...}`.
  Future<Map<String, dynamic>> request(
    String cmd, [
    Map<String, Object?> args = const {},
    Duration timeout = const Duration(seconds: 6),
  ]) async {
    final process = await _ensureProcess();
    if (process == null) return {'ok': false, 'error': 'NO_PYTHON'};

    final id = _nextId++;
    final completer = Completer<Map<String, dynamic>>();
    _pending[id] = completer;
    try {
      process.stdin.writeln(jsonEncode({...args, 'id': id, 'cmd': cmd}));
    } catch (e) {
      _pending.remove(id);
      _reset();
      return {'ok': false, 'error': 'BRIDGE_DIED'};
    }
    return completer.future.timeout(timeout, onTimeout: () {
      debugPrint('ImpressBridge: "$cmd" timed out, restarting bridge');
      _pending.remove(id);
      _reset();
      return {'ok': false, 'error': 'TIMEOUT'};
    });
  }

  /// Fire-and-forget request (no reply), used for the laser position stream.
  void send(String cmd, Map<String, Object?> args) {
    final process = _process;
    if (process == null) {
      _ensureProcess();
      return;
    }
    try {
      process.stdin.writeln(jsonEncode({...args, 'cmd': cmd, 'noreply': true}));
    } catch (_) {
      _reset();
    }
  }
}
