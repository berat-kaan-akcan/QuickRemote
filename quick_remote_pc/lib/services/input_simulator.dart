import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';

import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:win32/win32.dart';

/// Windows input simulator using Win32 SendInput API.
/// Simulates keyboard key presses and system commands.
class InputSimulator {
  /// Callback invoked when a COM/PowerShell command fails.
  /// The string parameter contains a short error description.
  static void Function(String detail)? onCommandError;
  /// Simulate a single key press (down + up).
  static void pressKey(int vkCode) {
    final inputs = calloc<INPUT>(2);

    // Key down
    inputs[0].type = INPUT_KEYBOARD;
    inputs[0].ki.wVk = VIRTUAL_KEY(vkCode);
    inputs[0].ki.dwFlags = KEYBD_EVENT_FLAGS(0);

    // Key up
    inputs[1].type = INPUT_KEYBOARD;
    inputs[1].ki.wVk = VIRTUAL_KEY(vkCode);
    inputs[1].ki.dwFlags = KEYEVENTF_KEYUP;

    SendInput(2, inputs, sizeOf<INPUT>());
    calloc.free(inputs);
  }

  /// Simulate a key combination (e.g., Win+L).
  static void pressKeyCombo(List<int> vkCodes) {
    final count = vkCodes.length * 2;
    final inputs = calloc<INPUT>(count);

    // All keys down
    for (var i = 0; i < vkCodes.length; i++) {
      inputs[i].type = INPUT_KEYBOARD;
      inputs[i].ki.wVk = VIRTUAL_KEY(vkCodes[i]);
      inputs[i].ki.dwFlags = KEYBD_EVENT_FLAGS(0);
    }

    // All keys up (reverse order)
    for (var i = 0; i < vkCodes.length; i++) {
      final idx = vkCodes.length + i;
      inputs[idx].type = INPUT_KEYBOARD;
      inputs[idx].ki.wVk = VIRTUAL_KEY(vkCodes[vkCodes.length - 1 - i]);
      inputs[idx].ki.dwFlags = KEYEVENTF_KEYUP;
    }

    SendInput(count, inputs, sizeOf<INPUT>());
    calloc.free(inputs);
  }

  // --- Command handlers ---

  /// Slide next (Page Down)
  static void slideNext() => pressKey(VK_NEXT);

  /// Slide previous (Page Up)
  static void slidePrev() => pressKey(VK_PRIOR);

  /// Start presentation (F5)
  static Future<void> slideStart() async {
    // Attempt to disable Protected View via COM automation
    try {
      final script = r'''
try {
    $ppt = [System.Runtime.InteropServices.Marshal]::GetActiveObject("PowerPoint.Application")
    if ($ppt -ne $null -and $ppt.ActiveProtectedViewWindow -ne $null) {
        $ppt.ActiveProtectedViewWindow.Edit()
        Start-Sleep -Milliseconds 150
    }
} catch {
    Write-Error $_.Exception.Message
}
''';
      await _PowerShellRunner.execute(script);
    } catch (e) {
      debugPrint('Exception in slideStart: $e');
    }

    // Send F5 to start presentation
    pressKey(VK_F5);
  }

  /// Start presentation from a specific slide
  static Future<void> slideStartAt(int slideNumber) async {
    await slideStart();
    
    // Wait for the presentation to load in full screen using polling
    bool isFullScreen = false;
    for (int i = 0; i < 20; i++) {
      await Future.delayed(const Duration(milliseconds: 100));
      final script = r'''
try {
    $ppt = [System.Runtime.InteropServices.Marshal]::GetActiveObject("PowerPoint.Application")
    if ($ppt -ne $null -and $ppt.SlideShowWindows.Count -gt 0) {
        Write-Output "READY"
    } else {
        Write-Output "NOT_READY"
    }
} catch {
    Write-Output "NOT_READY"
}
''';
      try {
        final result = await _PowerShellRunner.execute(script);
        if (result.trim() == 'READY') {
          isFullScreen = true;
          break;
        }
      } catch (_) {}
    }

    if (!isFullScreen) {
      debugPrint('Warning: PowerPoint did not enter full screen within 2 seconds. Attempting to send slide number anyway.');
    }
    
    // Send the slide number digits
    final chars = slideNumber.toString().codeUnits;
    for (final charCode in chars) {
      pressKey(charCode); // '0'-'9' map perfectly to VK_0 - VK_9
    }
    
    // Press Enter to go to the slide
    pressKey(VK_RETURN);
  }

  /// End presentation (Escape)
  /// End presentation (Escape)
  static Future<void> slideEnd() async {
    // 1. Send ESC to exit presentation
    pressKey(VK_ESCAPE);

    // 2. Wait for the "Keep Ink" or "Save Changes" prompt to appear
    await Future.delayed(const Duration(milliseconds: 350));

    // 3. Check if a dialog took focus
    final hwnd = GetForegroundWindow();
    final classNamePtr = wsalloc(256);
    GetClassName(hwnd, classNamePtr, 256);
    final className = classNamePtr.toDartString();
    free(classNamePtr);

    // 4. If the foreground window is a standard dialog (#32770) or Office dialog (NUIDialog)
    if (className == '#32770' || className == 'NUIDialog') {
      // The default focused button is usually "Keep" or "Save".
      // Pressing TAB moves focus to "Discard" (Çıkar) or "Don't Save".
      pressKey(VK_TAB);
      await Future.delayed(const Duration(milliseconds: 50));
      // Press ENTER to click it.
      pressKey(VK_RETURN);
    }
  }

  /// Lock workstation
  static void lockPC() => LockWorkStation();

  static bool _isLaserActive = false;

  /// Toggle PowerPoint laser pointer using keyboard shortcuts (Ctrl+L / Ctrl+A)
  static void toggleLaserCursor() {
    if (_isLaserActive) {
      // Turn laser off (Ctrl + A for Arrow in PowerPoint)
      pressKeyCombo([VK_CONTROL, 0x41]); // 0x41 is 'A'
      _isLaserActive = false;
    } else {
      // Turn laser on (Ctrl + L for Laser in PowerPoint)
      pressKeyCombo([VK_CONTROL, 0x4C]); // 0x4C is 'L'
      _isLaserActive = true;
    }
  }

  /// Simulate left mouse click
  static void leftClick() {
    final inputs = calloc<INPUT>(2);
    inputs[0].type = const INPUT_TYPE(0);
    inputs[0].mi.dwFlags = MOUSEEVENTF_LEFTDOWN;
    inputs[1].type = const INPUT_TYPE(0);
    inputs[1].mi.dwFlags = MOUSEEVENTF_LEFTUP;
    SendInput(2, inputs, sizeOf<INPUT>());
    calloc.free(inputs);
  }

  /// Simulate right mouse click
  static void rightClick() {
    final inputs = calloc<INPUT>(2);
    inputs[0].type = const INPUT_TYPE(0);
    inputs[0].mi.dwFlags = MOUSEEVENTF_RIGHTDOWN;
    inputs[1].type = const INPUT_TYPE(0);
    inputs[1].mi.dwFlags = MOUSEEVENTF_RIGHTUP;
    SendInput(2, inputs, sizeOf<INPUT>());
    calloc.free(inputs);
  }

  /// Left mouse button down
  static void leftDown() {
    final inputs = calloc<INPUT>(1);
    inputs[0].type = const INPUT_TYPE(0);
    inputs[0].mi.dwFlags = MOUSEEVENTF_LEFTDOWN;
    SendInput(1, inputs, sizeOf<INPUT>());
    calloc.free(inputs);
  }

  /// Left mouse button up
  static void leftUp() {
    final inputs = calloc<INPUT>(1);
    inputs[0].type = const INPUT_TYPE(0);
    inputs[0].mi.dwFlags = MOUSEEVENTF_LEFTUP;
    SendInput(1, inputs, sizeOf<INPUT>());
    calloc.free(inputs);
  }



  static Future<void> setPenColor(int bgrColor) async {
    final script = '''
try {
    \$ppt = [System.Runtime.InteropServices.Marshal]::GetActiveObject("PowerPoint.Application")
    if (\$ppt -ne \$null -and \$ppt.SlideShowWindows.Count -gt 0) {
        \$ppt.SlideShowWindows.Item(1).View.PointerColor.RGB = $bgrColor
    }
} catch {
    Write-Error \$_.Exception.Message
}
''';
    try {
      await _PowerShellRunner.execute(script);
    } catch (e) {
      debugPrint('Exception in setPenColor: $e');
      onCommandError?.call('Kalem rengi değiştirilemedi: $e');
    }
  }

  /// Execute a command string from the client.
  static void executeCommand(String command) {
    if (command.startsWith('SET_PEN_COLOR:')) {
      final bgrStr = command.split(':')[1];
      final bgr = int.tryParse(bgrStr);
      if (bgr != null && bgr >= 0 && bgr <= 16777215) {
        setPenColor(bgr);
      } else {
        debugPrint('Invalid BGR color value: $bgrStr (must be 0-16777215)');
      }
      return;
    }

    if (command.startsWith('START_AT:')) {
      final slideStr = command.split(':')[1];
      final slideNumber = int.tryParse(slideStr);
      if (slideNumber != null) {
        slideStartAt(slideNumber);
      }
      return;
    }

    switch (command) {
      case 'NEXT':
        slideNext();
        break;
      case 'PREV':
        slidePrev();
        break;
      case 'START':
        slideStart();
        break;
      case 'END':
        slideEnd();
        break;

      case 'LOCK':
        lockPC();
        break;
      case 'LASER_CURSOR':
        toggleLaserCursor();
        break;
      case 'MODE_ARROW':
        pressKeyCombo([VK_CONTROL, 0x41]); // Ctrl + A
        _isLaserActive = false;
        break;
      case 'MODE_LASER':
        // PowerPoint'in kendi lazer işaretçisini aç (Ctrl + L)
        pressKeyCombo([VK_CONTROL, 0x4C]); // Ctrl + L
        _isLaserActive = true;
        break;
      case 'MODE_PEN':
        pressKeyCombo([VK_CONTROL, 0x50]); // Ctrl + P (Kalem)
        _isLaserActive = false;
        break;
      case 'MODE_HIGHLIGHTER':
        pressKeyCombo([VK_CONTROL, 0x49]); // Ctrl + I (Vurgulayıcı)
        _isLaserActive = false;
        break;
      case 'MODE_ERASER':
        pressKeyCombo([VK_CONTROL, 0x45]); // Ctrl + E
        _isLaserActive = false;
        break;
      case 'LEFT_CLICK':
        leftClick();
        break;
      case 'RIGHT_CLICK':
        rightClick();
        break;
      case 'LEFT_DOWN':
        leftDown();
        break;
      case 'LEFT_UP':
        leftUp();
        break;
      case 'LASER_OFF':
        // PowerPoint'te lazeri kapatmak için normal Ok moduna dön (Ctrl + A)
        pressKeyCombo([VK_CONTROL, 0x41]); // Ctrl + A
        _isLaserActive = false;
        break;
      default:
        debugPrint('Unknown command: $command');
    }
  }

  /// Get current slide state (current slide, total slides, notes)
  static Future<Map<String, dynamic>?> getSlideState() async {
    const script = r'''
try {
    $ppt = [System.Runtime.InteropServices.Marshal]::GetActiveObject("PowerPoint.Application")
    if ($ppt -ne $null -and $ppt.SlideShowWindows.Count -gt 0) {
        $view = $ppt.SlideShowWindows.Item(1).View
        $current = $view.CurrentShowPosition
        $total = $ppt.ActivePresentation.Slides.Count
        $slide = $ppt.ActivePresentation.Slides.Item($current)
        $notes = ""
        if ($slide.HasNotesPage) {
            $shapes = $slide.NotesPage.Shapes
            foreach ($shape in $shapes) {
                if ($shape.Type -eq 14 -or $shape.HasTextFrame) {
                    $text = $shape.TextFrame.TextRange.Text
                    if ($text -ne $null -and $text.Trim() -ne "") {
                        $notes += $text + "`n"
                    }
                }
            }
        }
        $data = @{
            current = $current
            total = $total
            notes = $notes.Trim()
        }
        $data | ConvertTo-Json -Compress
    } else {
        Write-Output "POWERPOINT_NOT_RUNNING"
    }
} catch {
    Write-Output "POWERPOINT_NOT_RUNNING"
}
''';
    try {
      final output = await _PowerShellRunner.execute(script);
      if (output.trim() == 'POWERPOINT_NOT_RUNNING') {
        return {'error': 'POWERPOINT_NOT_RUNNING'};
      }
      if (output.isNotEmpty && output.startsWith('{')) {
        return jsonDecode(output) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('Exception in getSlideState: $e');
      onCommandError?.call('Slayt durumu alınamadı: $e');
    }
    return null;
  }
}

class _PSJob {
  final String script;
  final Completer<String> completer;
  _PSJob(this.script, this.completer);
}

class _PowerShellRunner {
  static Process? _process;
  static bool _isStarting = false;
  static Completer<String>? _currentCompleter;
  static final StringBuffer _currentOutput = StringBuffer();
  static final List<_PSJob> _jobQueue = [];
  static bool _isProcessing = false;

  static Future<void> _ensureProcess() async {
    // The exitCode listener handles setting _process to null if it dies.
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
      _process = await Process.start('powershell', ['-NoProfile', '-NonInteractive', '-Command', '-']);
      
      _process!.exitCode.then((code) {
        debugPrint('PowerShell process exited with code $code');
        _process = null;
        if (_currentCompleter != null && !_currentCompleter!.isCompleted) {
          _currentCompleter!.complete('');
          _currentCompleter = null;
        }
        _currentOutput.clear();
      });

      _process!.stdout.transform(utf8.decoder).transform(const LineSplitter()).listen((line) {
        if (line.trim() == '___PS_DONE___') {
          if (_currentCompleter != null && !_currentCompleter!.isCompleted) {
            _currentCompleter!.complete(_currentOutput.toString().trim());
            _currentCompleter = null;
            _currentOutput.clear();
            _processNext();
          }
        } else {
          _currentOutput.writeln(line);
        }
      });

      _process!.stderr.transform(utf8.decoder).transform(const LineSplitter()).listen((line) {
        debugPrint('PowerShell Error: $line');
      });
    } catch (e) {
      debugPrint('Failed to start PowerShell: $e');
    } finally {
      _isStarting = false;
    }
  }

  static Future<String> execute(String script) async {
    final completer = Completer<String>();
    _jobQueue.add(_PSJob(script, completer));
    if (!_isProcessing) {
      _processNext();
    }
    return completer.future;
  }

  static Future<void> _processNext() async {
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
      _process!.stdin.writeln(job.script);
      _process!.stdin.writeln('Write-Output "___PS_DONE___"');
    } catch (e) {
      debugPrint('PowerShell stdin error: $e');
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
