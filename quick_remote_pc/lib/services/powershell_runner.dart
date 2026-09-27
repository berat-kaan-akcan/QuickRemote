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
      _process = await Process.start('powershell', [
        '-NoProfile',
        '-NonInteractive',
        '-Command',
        '-',
      ]);

      _process!.stdin.writeln('[Console]::OutputEncoding = [System.Text.Encoding]::UTF8');

      _process!.exitCode.then((code) {
        debugPrint('PowerShell process [$name] exited with code $code');
        _process = null;
        if (_currentCompleter != null && !_currentCompleter!.isCompleted) {
          _currentCompleter!.complete('');
          _currentCompleter = null;
        }
        _currentOutput.clear();
      });

      _process!.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {
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

      _process!.stderr
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
    if (_process != null) {
      _process!.kill(ProcessSignal.sigkill);
      _process = null;
    }
    if (_currentCompleter != null && !_currentCompleter!.isCompleted) {
      debugPrint('PowerShell runner [$name] completing with timeout empty string');
      _currentCompleter!.complete('');
      _currentCompleter = null;
    }
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

    if (_process == null) {
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

      _process!.stdin.writeln(job.script);
      _process!.stdin.writeln('Write-Output "___PS_DONE___"');
    } catch (e) {
      debugPrint('PowerShell stdin error in [$name]: $e');
      _executionTimeout?.cancel();
      _process = null;
      if (_currentCompleter != null && !_currentCompleter!.isCompleted) {
        _currentCompleter = null;
      }
      _currentOutput.clear();
      // Retry the job
      _jobQueue.insert(0, job);
      _isProcessing = false;
      _processNext();
    }
  }
}
