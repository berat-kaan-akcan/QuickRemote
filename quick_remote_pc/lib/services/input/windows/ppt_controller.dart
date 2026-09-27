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

  static Future<void> slideStartAt(int slideNumber) async {
    await slideStart();
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
        final result = await PowerShellRunner.execute(script);
        if (result.trim() == 'READY') {
          isFullScreen = true;
          break;
        }
      } catch (_) {}
    }

    if (!isFullScreen) {
      debugPrint('Warning: PowerPoint did not enter full screen within 2 seconds. Attempting to send slide number anyway.');
    }
    final chars = slideNumber.toString().codeUnits;
    for (final charCode in chars) {
      KeyboardSimulator.pressKey(charCode); // '0'-'9' map perfectly to VK_0 - VK_9
    }
    KeyboardSimulator.pressKey(VK_RETURN);
  }

  static Future<void> slideEnd() async {
    KeyboardSimulator.pressKey(VK_ESCAPE);
    await Future.delayed(const Duration(milliseconds: 350));
    final hwnd = GetForegroundWindow();
    final classNamePtr = wsalloc(256);
    GetClassName(hwnd, classNamePtr, 256);
    final className = classNamePtr.toDartString();
    free(classNamePtr);

    if (className == '#32770' || className == 'NUIDialog') {
      KeyboardSimulator.pressKey(VK_TAB);
      await Future.delayed(const Duration(milliseconds: 50));
      KeyboardSimulator.pressKey(VK_RETURN);
    }
  }

  static void blackScreen() => KeyboardSimulator.pressKey(0x42);
  static void whiteScreen() => KeyboardSimulator.pressKey(0x57);
  static void eraseAllInk() => KeyboardSimulator.pressKey(0x45);

  static void toggleLaserCursor() {
    if (_isLaserActive) {
      KeyboardSimulator.pressKeyCombo([VK_CONTROL, 0x41]);
      _isLaserActive = false;
    } else {
      KeyboardSimulator.pressKeyCombo([VK_CONTROL, 0x4C]);
      _isLaserActive = true;
    }
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

  static Future<void> pptMediaPlayPause() async {
    const comScript = r'''
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
                    if ($player.State -eq 0) {
                        $player.Pause()
                    } else {
                        $player.Play()
                    }
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
''';
    try {
      final result = (await PowerShellRunner.execute(comScript)).trim();
      if (result == 'NO_SLIDESHOW') return;

      int currentSlide = -1;
      bool comSuccess = false;
      
      if (result.startsWith('COM_OK_')) {
        comSuccess = true;
        currentSlide = int.tryParse(result.substring(7)) ?? -1;
      } else if (result.startsWith('COM_FAIL_')) {
        comSuccess = false;
        currentSlide = int.tryParse(result.substring(9)) ?? -1;
      }
      // If it starts with ERROR or anything else, comSuccess remains false and currentSlide remains -1.

      if (comSuccess) return;

      final focused = await _focusPptSlideShow();
      if (!focused) return;
      
      // If currentSlide is -1 (meaning COM failed entirely), we might just press Tab anyway.
      // But we can't reliably track _lastMediaSlideNumber. Let's just assume we need to press Tab if we don't know,
      // or maybe we should NOT press tab if we don't know the slide? 
      // Actually, if currentSlide == -1, we should probably reset _lastMediaSlideNumber so it presses Tab.
      if (currentSlide == -1) {
          KeyboardSimulator.pressKey(VK_TAB);
          await Future.delayed(const Duration(milliseconds: 200));
          _lastMediaSlideNumber = -1; // Reset it so next time we also press Tab, because we don't know if slide changed.
      } else if (currentSlide != _lastMediaSlideNumber) {
          KeyboardSimulator.pressKey(VK_TAB);
          await Future.delayed(const Duration(milliseconds: 200));
          _lastMediaSlideNumber = currentSlide;
      }
      
      KeyboardSimulator.pressKeyCombo([VK_MENU, 0x50]); // Alt + P
    } catch (e) {
      debugPrint('pptMediaPlayPause error: $e');
    }
  }

  static Future<void> pptMediaRewind() async {
    const comScript = r'''
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
                    $player.Pause()
                    Start-Sleep -Milliseconds 50
                    $player.CurrentPosition = 0
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
''';
    try {
      final result = (await PowerShellRunner.execute(comScript)).trim();
      if (result == 'NO_SLIDESHOW') return;

      int currentSlide = -1;
      bool comSuccess = false;
      
      if (result.startsWith('COM_OK_')) {
        comSuccess = true;
        currentSlide = int.tryParse(result.substring(7)) ?? -1;
      } else if (result.startsWith('COM_FAIL_')) {
        comSuccess = false;
        currentSlide = int.tryParse(result.substring(9)) ?? -1;
      }

      if (comSuccess) return;

      final focused = await _focusPptSlideShow();
      if (!focused) return;
      
      if (currentSlide == -1) {
          KeyboardSimulator.pressKey(VK_TAB);
          await Future.delayed(const Duration(milliseconds: 200));
          _lastMediaSlideNumber = -1;
      } else if (currentSlide != _lastMediaSlideNumber) {
          KeyboardSimulator.pressKey(VK_TAB);
          await Future.delayed(const Duration(milliseconds: 200));
          _lastMediaSlideNumber = currentSlide;
      }
      
      KeyboardSimulator.pressKeyCombo([VK_MENU, VK_HOME]); // Alt + Home
    } catch (e) {
      debugPrint('pptMediaRewind error: $e');
    }
  }
}
