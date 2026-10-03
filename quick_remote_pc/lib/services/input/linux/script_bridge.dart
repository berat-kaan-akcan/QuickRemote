import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// A persistent Python helper from assets/linux/ that takes one JSON request
/// per line on stdin and answers one JSON reply per line, matched by `id` —
/// the Linux counterpart of PowerShellRunner.
abstract class ScriptBridge {
  ScriptBridge(this.name, this.asset);

  /// Shown in log lines.
  final String name;

  /// The script under assets/linux/.
  final String asset;

  /// Overridable in tests to run the script from the source tree.
  @visibleForTesting
  String? scriptPathOverride;

  /// The interpreter, or null when it is not installed: requests then fail
  /// with [missingError] without starting anything.
  Future<String?> interpreter();

  String get missingError => 'NO_PYTHON';

  /// Arguments after the script path.
  List<String> get scriptArguments => const [];

  /// Whether a request that times out kills the process. A bridge whose
  /// process holds a connection it cannot get back keeps it instead.
  bool get restartOnTimeout => true;

  Process? _process;
  Future<Process?>? _starting;
  int _nextId = 1;
  final Map<int, Completer<Map<String, dynamic>>> _pending = {};

  /// Lines carrying an `event` (replies, or unasked lines).
  void Function(Map<String, dynamic> event)? onEvent;

  Future<String> _scriptPath() async {
    if (scriptPathOverride != null) return scriptPathOverride!;
    final source = await rootBundle.loadString('assets/linux/$asset');
    final dir = await getApplicationSupportDirectory();
    final file = File(p.join(dir.path, asset));
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
    final exe = await interpreter();
    if (exe == null) return null;
    try {
      final process = await Process.start(exe, ['-u', await _scriptPath(), ...scriptArguments]);
      process.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(_onLine);
      process.stderr
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) => debugPrint('$name stderr: $line'));
      process.exitCode.then((code) {
        debugPrint('$name exited with code $code');
        if (identical(_process, process)) _reset();
      });
      _process = process;
      return process;
    } catch (e) {
      debugPrint('$name: failed to start $exe: $e');
      return null;
    }
  }

  void _onLine(String line) {
    try {
      final reply = jsonDecode(line) as Map<String, dynamic>;
      if (reply.containsKey('event')) onEvent?.call(reply);
      final id = reply['id'];
      if (id != null) _pending.remove(id)?.complete(reply);
    } catch (e) {
      debugPrint('$name: bad reply "$line": $e');
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

  /// Stops the process; the next request starts a new one.
  void restart() => _reset();

  /// Sends [cmd] and waits for the reply. Never throws: failures come back as
  /// `{'ok': false, 'error': ...}`.
  Future<Map<String, dynamic>> request(
    String cmd, [
    Map<String, Object?> args = const {},
    Duration timeout = const Duration(seconds: 6),
  ]) async {
    final process = await _ensureProcess();
    if (process == null) return {'ok': false, 'error': missingError};

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
      _pending.remove(id);
      if (restartOnTimeout) {
        debugPrint('$name: "$cmd" timed out, restarting bridge');
        _reset();
      } else {
        debugPrint('$name: "$cmd" timed out');
      }
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
