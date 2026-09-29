import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

class PSJob {
  final String script;
  final Completer<String> completer;
  PSJob(this.script, this.completer);
}

class PowerShellRunner {
  Process? _process;
  bool _isStarting = false;
  Completer<String>? _currentCompleter;
  final StringBuffer _currentOutput = StringBuffer();
  final List<PSJob> _jobQueue = [];
  bool _isProcessing = false;
  Timer? _executionTimeout;
  final String name;

  PowerShellRunner(this.name);

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
      final process = await Process.start(executable, [
        '-NoProfile',
        '-NonInteractive',
        '-Command',
        '-',
      ]);
      _process = process;

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
        _currentOutput.clear();
        _isProcessing = false;
        _processNext();
      });

      process.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {
            if (!identical(_process, process)) return;
            if (line.trim() == '___PS_DONE___') {
              _executionTimeout?.cancel();
              if (_currentCompleter != null &&
                  !_currentCompleter!.isCompleted) {
                _currentCompleter!.complete(_currentOutput.toString().trim());
                _currentCompleter = null;
                _currentOutput.clear();
                _processNext();
              }
            } else {
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

    try {
      _executionTimeout?.cancel();
      _executionTimeout = Timer(const Duration(seconds: 5), () {
        debugPrint('PowerShell script execution timed out (5s) in [$name] runner. Killing process.');
        _killProcessAndReset();
      });

      process.stdin.writeln(job.script);
      process.stdin.writeln('Write-Output "___PS_DONE___"');
    } catch (e) {
      debugPrint('PowerShell stdin error in [$name]: $e');
      _executionTimeout?.cancel();
      _process = null;
      process.kill(ProcessSignal.sigkill);
      _currentCompleter = null;
      _currentOutput.clear();
      // Retry the job on a fresh process
      _jobQueue.insert(0, job);
      _isProcessing = false;
      _processNext();
    }
  }
}
