import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:win32/win32.dart';
import 'keyboard_simulator.dart';
import '../../powershell_runner.dart';
import '../../input_simulator.dart'; // For InputSimulator.onCommandError

class PptController {
  static bool _isLaserActive = false;
  static int _lastMediaSlideNumber = -1;

  static void slideNext() => KeyboardSimulator.pressKey(VK_NEXT);
  static void slidePrev() => KeyboardSimulator.pressKey(VK_PRIOR);

  static Future<void> slideStart() async {
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
      await PowerShellRunner.execute(script);
    } catch (e) {
      debugPrint('Exception in slideStart: $e');
    }
    KeyboardSimulator.pressKey(VK_F5);
  }

  /// Starts the show and jumps to [slideNumber] through COM. Typing the
  /// number + Enter (PowerPoint's own shortcut) would land in whatever window
  /// has the focus when the show did not open.
  static Future<void> slideStartAt(int slideNumber) async {
    await slideStart();
    // $slideNumber is an int validated by CommandRouter (1..9999).
    final script = '''
try {
    \$ppt = [System.Runtime.InteropServices.Marshal]::GetActiveObject("PowerPoint.Application")
    for (\$i = 0; \$i -lt 20 -and \$ppt.SlideShowWindows.Count -eq 0; \$i++) {
        Start-Sleep -Milliseconds 100
    }
    if (\$ppt.SlideShowWindows.Count -eq 0) {
        Write-Output "NOT_READY"
        return
    }
    \$view = \$ppt.SlideShowWindows.Item(1).View
    \$total = \$ppt.SlideShowWindows.Item(1).Presentation.Slides.Count
    \$view.GotoSlide([Math]::Min($slideNumber, \$total))
    Write-Output "OK"
} catch {
    Write-Output "NOT_READY"
}
''';
    try {
      final result = (await PowerShellRunner.execute(script)).trim();
      if (result != 'OK') {
        InputSimulator.onCommandError?.call('Slayt gösterisi başlatılamadı.');
      }
    } catch (e) {
      debugPrint('Exception in slideStartAt: $e');
    }
  }

  static Future<void> slideEnd() async {
    KeyboardSimulator.pressKey(VK_ESCAPE);
    await Future.delayed(const Duration(milliseconds: 350));
    final hwnd = GetForegroundWindow();
    final classNamePtr = wsalloc(256);
    GetClassName(hwnd, classNamePtr, 256);
    final className = classNamePtr.toDartString();
    free(classNamePtr);

    // PowerPoint's "keep ink annotations?" prompt. '#32770' is the class of
    // every standard dialog, so check the owner too: never answer another
    // application's dialog.
    if ((className == '#32770' || className == 'NUIDialog') && _isPowerPointWindow(hwnd)) {
      KeyboardSimulator.pressKey(VK_TAB);
      await Future.delayed(const Duration(milliseconds: 50));
      KeyboardSimulator.pressKey(VK_RETURN);
    }
  }

  static bool _isPowerPointWindow(HWND hwnd) {
    final pid = calloc<Uint32>();
    final size = calloc<Uint32>()..value = 1024;
    final path = wsalloc(1024);
    try {
      GetWindowThreadProcessId(hwnd, pid);
      final process = OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION, false, pid.value).value;
      if (process.address == 0) return false;
      try {
        if (!QueryFullProcessImageName(process, PROCESS_NAME_WIN32, path, size).value) return false;
        return path.toDartString().toLowerCase().endsWith(r'\powerpnt.exe');
      } finally {
        CloseHandle(process);
      }
    } finally {
      calloc.free(pid);
      calloc.free(size);
      free(path);
    }
  }

  static Future<void> blackScreen() => pressInSlideShow([0x42]); // B
  static Future<void> whiteScreen() => pressInSlideShow([0x57]); // W
  static Future<void> eraseAllInk() => pressInSlideShow([0x45]); // E

  static Future<void> toggleLaserCursor() async {
    final laser = !_isLaserActive;
    if (await pressInSlideShow([VK_CONTROL, laser ? 0x4C : 0x41])) _isLaserActive = laser;
  }

  /// Presses a slideshow shortcut only while PowerPoint has the focus,
  /// bringing its slideshow window forward when another window has it.
  /// Ctrl+A, B, E, ... in a focused Word window would select all and
  /// replace the text. Returns whether the keys were sent.
  static Future<bool> pressInSlideShow(List<int> keys) async {
    if (!_isPowerPointWindow(GetForegroundWindow()) && !await _focusPptSlideShow()) {
      debugPrint('Slideshow shortcut skipped: PowerPoint does not have the focus');
      return false;
    }
    KeyboardSimulator.pressKeyCombo(keys);
    return true;
  }
  
  static void setLaserActive(bool active) {
      _isLaserActive = active;
  }

  static Future<void> setPenColor(int bgrColor) async {
    final script = '''
try {
    \$ppt = [System.Runtime.InteropServices.Marshal]::GetActiveObject("PowerPoint.Application")
    if (\$ppt -ne \$null -and \$ppt.SlideShowWindows.Count -gt 0) {
        \$ppt.SlideShowWindows.Item(1).View.PointerColor.RGB = $bgrColor
    } else {
        Write-Output "ERROR: SLIDESHOW_NOT_ACTIVE"
    }
} catch {
    Write-Output "ERROR: \$(\$_.Exception.Message)"
}
''';
    try {
      final output = await PowerShellRunner.execute(script);
      debugPrint('setPenColor output: $output');
      if (output.trim().startsWith('ERROR:')) {
        String errorMsg = output.trim().substring(7).trim();
        if (errorMsg.contains('SLIDESHOW_NOT_ACTIVE')) {
          errorMsg = 'Slayt gösterisi aktif değil.';
        } else if (errorMsg.contains('MK_E_UNAVAILABLE') || errorMsg.contains('GetActiveObject')) {
          errorMsg = 'PowerPoint çalışmıyor veya erişilebilir değil.';
        } else if (errorMsg.contains('0x800706BA') || errorMsg.contains('RPC server is unavailable')) {
          errorMsg = 'PowerPoint yanıt vermiyor.';
        }
        debugPrint('setPenColor failed: $errorMsg');
        InputSimulator.onCommandError?.call(errorMsg);
      }
    } catch (e) {
      debugPrint('Exception in setPenColor: $e');
      InputSimulator.onCommandError?.call('Beklenmeyen bir hata oluştu: $e');
    }
  }

  static Future<bool> _focusPptSlideShow() async {
    const hwndScript = r'''
try {
    $ppt = [System.Runtime.InteropServices.Marshal]::GetActiveObject("PowerPoint.Application")
    if ($ppt -ne $null -and $ppt.SlideShowWindows.Count -gt 0) {
        Write-Output $ppt.SlideShowWindows.Item(1).HWND
    } else {
        Write-Output "0"
    }
} catch {
    Write-Output "0"
}
''';
    try {
      final hwndStr = (await PowerShellRunner.execute(hwndScript)).trim();
      final hwndVal = int.tryParse(hwndStr) ?? 0;
      if (hwndVal == 0) return false;

      final hwnd = HWND(Pointer.fromAddress(hwndVal));
      final foreHwnd = GetForegroundWindow();
      if (foreHwnd == hwnd) return true;

      final foreThread = GetWindowThreadProcessId(foreHwnd, nullptr);
      final pidPtr = calloc<Uint32>();
      final targetThread = GetWindowThreadProcessId(hwnd, pidPtr);
      final targetPid = pidPtr.value;
      calloc.free(pidPtr);
      final curThread = GetCurrentThreadId();

      AllowSetForegroundWindow(targetPid);

      bool attached1 = false;
      bool attached2 = false;
      if (foreThread != curThread) {
        attached1 = AttachThreadInput(curThread, foreThread, true);
      }
      if (foreThread != targetThread) {
        attached2 = AttachThreadInput(curThread, targetThread, true);
      }

      BringWindowToTop(hwnd);
      SetForegroundWindow(hwnd);

      if (attached1) AttachThreadInput(curThread, foreThread, false);
      if (attached2) AttachThreadInput(curThread, targetThread, false);

      await Future.delayed(const Duration(milliseconds: 200));
      return GetForegroundWindow() == hwnd;
    } catch (e) {
      debugPrint('_focusPptSlideShow error: $e');
      return false;
    }
  }

  static Future<void> pptMediaPlayPause() => _pptMedia(
        name: 'pptMediaPlayPause',
        playerAction: r'''
                    if ($player.State -eq 0) {
                        $player.Pause()
                    } else {
                        $player.Play()
                    }''',
        fallbackKeys: [VK_MENU, 0x50], // Alt + P
      );

  static Future<void> pptMediaRewind() => _pptMedia(
        name: 'pptMediaRewind',
        playerAction: r'''
                    $player.Pause()
                    Start-Sleep -Milliseconds 50
                    $player.CurrentPosition = 0''',
        fallbackKeys: [VK_MENU, VK_HOME], // Alt + Home
      );

  /// Runs [playerAction] on the first media player of the current slide
  /// through COM. When COM can't reach one, focuses the slideshow, selects
  /// the media with Tab (once per slide) and presses [fallbackKeys].
  static Future<void> _pptMedia({
    required String name,
    required String playerAction,
    required List<int> fallbackKeys,
  }) async {
    final comScript = r'''
try {
    $ppt = [System.Runtime.InteropServices.Marshal]::GetActiveObject("PowerPoint.Application")
    if ($ppt -eq $null -or $ppt.SlideShowWindows.Count -eq 0) {
        Write-Output "NO_SLIDESHOW"
        return
    }

    $view  = $ppt.SlideShowWindows.Item(1).View
    $slide = $view.Slide
    $slideNum = $slide.SlideNumber

    $mediaControlled = $false
    try {
        for ($i = 1; $i -le $slide.Shapes.Count; $i++) {
            try {
                $shape = $slide.Shapes.Item($i)
                $player = $view.Player($shape.Name)
                if ($player -ne $null) {
__PLAYER_ACTION__
                    $mediaControlled = $true
                    break
                }
            } catch {}
        }
    } catch {
        $mediaControlled = $false
    }

    if ($mediaControlled) {
        Write-Output "COM_OK_$slideNum"
    } else {
        Write-Output "COM_FAIL_$slideNum"
    }
} catch {
    Write-Output "ERROR: $($_.Exception.Message)"
}
'''.replaceFirst('__PLAYER_ACTION__', playerAction);
    try {
      final result = (await PowerShellRunner.execute(comScript)).trim();
      if (result == 'NO_SLIDESHOW') return;

      // ERROR or anything unexpected: COM failed and the slide is unknown (-1).
      int currentSlide = -1;
      if (result.startsWith('COM_OK_')) return;
      if (result.startsWith('COM_FAIL_')) {
        currentSlide = int.tryParse(result.substring(9)) ?? -1;
      }

      final focused = await _focusPptSlideShow();
      if (!focused) return;

      // Tab selects the media shape. Press it on every new slide, and always
      // when the slide is unknown since it may have changed.
      if (currentSlide == -1 || currentSlide != _lastMediaSlideNumber) {
        KeyboardSimulator.pressKey(VK_TAB);
        await Future.delayed(const Duration(milliseconds: 200));
        _lastMediaSlideNumber = currentSlide;
      }

      KeyboardSimulator.pressKeyCombo(fallbackKeys);
    } catch (e) {
      debugPrint('$name error: $e');
    }
  }
}
