import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';

class PSJob {
  final String script;
  final Completer<String> completer;

  /// The line that ends this job's output, see [PowerShellRunner.newMarker].
  final String marker = PowerShellRunner.newMarker();
  PSJob(this.script, this.completer);
}

/// Runs scripts in one persistent `powershell.exe`, one job at a time. A
/// job's output ends at its marker line, which the runner makes PowerShell
/// print after the script. The marker is random for every job: a script's
/// own output (a slide's notes, a file name) cannot hold it, so a line of
/// text never ends a job early and shifts every later answer by one. A
/// fixed `___PS_DONE___` did that until 2026-11.
class PowerShellRunner {
  Process? _process;
  bool _isStarting = false;
  Completer<String>? _currentCompleter;

  /// The marker of the job in flight; no other line ends it, not even the
  /// marker of an earlier job that arrives late.
  String? _currentMarker;
  final StringBuffer _currentOutput = StringBuffer();
  final List<PSJob> _jobQueue = [];
  bool _isProcessing = false;
  Timer? _executionTimeout;

  /// Whether the process has run no job yet. Its start (~2 s, more while the
  /// app itself starts) counts against the first job's time: with 5 s the
  /// first poll timed out on every app start (measured, Windows 11), and its
  /// replacement started cold again.
  bool _fresh = false;
  final String name;

  /// Starts the process; a fake one in tests.
  final Future<Process> Function() _start;

  /// How long a job may take, and the first job of a new process.
  final Duration _timeout;
  final Duration _firstTimeout;

  PowerShellRunner(
    this.name, {
    @visibleForTesting Future<Process> Function()? start,
    @visibleForTesting Duration timeout = const Duration(seconds: 5),
    @visibleForTesting Duration firstTimeout = const Duration(seconds: 15),
  }) : _start = start ?? _startPowerShell,
       _timeout = timeout,
       _firstTimeout = firstTimeout;

  static final _random = Random.secure();

  /// `___PS_DONE_<128 random bits>___`, new for every job.
  static String newMarker() {
    final hex = [for (var i = 0; i < 16; i++) _random.nextInt(256).toRadixString(16).padLeft(2, '0')].join();
    return '___PS_DONE_${hex}___';
  }

  static Future<Process> _startPowerShell() =>
      Process.start(executable, ['-NoProfile', '-NonInteractive', '-Command', '-']);

  static final PowerShellRunner _commandRunner = PowerShellRunner('Command');
  static final PowerShellRunner _pollingRunner = PowerShellRunner('Polling');

  /// Absolute path, so a `powershell.exe` placed in the app or working
  /// directory is never picked up through the executable search order.
  static String get executable {
    final root = Platform.environment['SystemRoot'] ?? r'C:\Windows';
    return '$root\\System32\\WindowsPowerShell\\v1.0\\powershell.exe';
  }

  static Future<String> execute(String script, {bool isPolling = false}) {
    if (isPolling) {
      return _pollingRunner._executeInternal(script);
    } else {
      return _commandRunner._executeInternal(script);
    }
  }

  Future<void> _ensureProcess() async {
    if (_process != null) {
      return;
    }
    if (_isStarting) {
      while (_isStarting) {
        await Future.delayed(const Duration(milliseconds: 10));
      }
      return;
    }

    _isStarting = true;
    try {
      final process = await _start();
      _process = process;
      _fresh = true;

      process.stdin.writeln('[Console]::OutputEncoding = [System.Text.Encoding]::UTF8');

      process.exitCode.then((code) {
        debugPrint('PowerShell process [$name] exited with code $code');
        // A process killed after a timeout exits after its replacement has
        // started; it must not touch the new process or the job it runs.
        if (!identical(_process, process)) return;
        _process = null;
        // No job in flight: the next _processNext starts a new process.
        final current = _currentCompleter;
        if (current == null) return;
        // The process died mid-job: fail that job and keep the queue moving.
        _executionTimeout?.cancel();
        if (!current.isCompleted) current.complete('');
        _currentCompleter = null;
        _currentMarker = null;
        _currentOutput.clear();
        _isProcessing = false;
        _processNext();
      });

      process.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {
            if (!identical(_process, process)) return;
            final marker = _currentMarker;
            if (marker != null && line.trim() == marker) {
              _executionTimeout?.cancel();
              _currentMarker = null;
              if (_currentCompleter != null &&
                  !_currentCompleter!.isCompleted) {
                _currentCompleter!.complete(_currentOutput.toString().trim());
                _currentCompleter = null;
                _currentOutput.clear();
                _processNext();
              }
            } else if (marker != null) {
              // Lines between jobs belong to none (a late line of a job
              // that was given up); they must not lead the next answer.
              _currentOutput.writeln(line);
            }
          });

      process.stderr
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {
            debugPrint('PowerShell Error [$name]: $line');
          });
    } catch (e) {
      debugPrint('Failed to start PowerShell [$name]: $e');
    } finally {
      _isStarting = false;
    }
  }

  /// Runs [script] after the jobs already waiting; its output, or '' when
  /// it timed out or the process could not run it.
  @visibleForTesting
  Future<String> run(String script) => _executeInternal(script);

  Future<String> _executeInternal(String script) async {
    final completer = Completer<String>();
    _jobQueue.add(PSJob(script, completer));
    if (!_isProcessing) {
      _processNext();
    }
    return completer.future;
  }

  void _killProcessAndReset() {
    _executionTimeout?.cancel();
    final process = _process;
    _process = null;
    process?.kill(ProcessSignal.sigkill);
    if (_currentCompleter != null && !_currentCompleter!.isCompleted) {
      debugPrint('PowerShell runner [$name] completing with timeout empty string');
      _currentCompleter!.complete('');
    }
    _currentCompleter = null;
    _currentMarker = null;
    _currentOutput.clear();

    _isProcessing = false;
    _processNext();
  }

  Future<void> _processNext() async {
    if (_jobQueue.isEmpty) {
      _isProcessing = false;
      return;
    }
    _isProcessing = true;
    await _ensureProcess();

    final process = _process;
    if (process == null) {
      final job = _jobQueue.removeAt(0);
      job.completer.complete('');
      _processNext();
      return;
    }

    final job = _jobQueue.removeAt(0);
    _currentCompleter = job.completer;
    _currentMarker = job.marker;

    try {
      _executionTimeout?.cancel();
      final limit = _fresh ? _firstTimeout : _timeout;
      _fresh = false;
      _executionTimeout = Timer(limit, () {
        debugPrint('PowerShell script execution timed out (${limit.inMilliseconds} ms) in [$name] runner. Killing process.');
        _killProcessAndReset();
      });

      process.stdin.writeln(job.script);
      process.stdin.writeln('Write-Output "${job.marker}"');
    } catch (e) {
      debugPrint('PowerShell stdin error in [$name]: $e');
      _executionTimeout?.cancel();
      _process = null;
      process.kill(ProcessSignal.sigkill);
      _currentCompleter = null;
      _currentMarker = null;
      _currentOutput.clear();
      // Retry the job on a fresh process
      _jobQueue.insert(0, job);
      _isProcessing = false;
      _processNext();
    }
  }
}
