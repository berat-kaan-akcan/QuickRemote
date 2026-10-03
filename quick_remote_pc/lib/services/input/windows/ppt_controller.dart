import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:win32/win32.dart';
import 'keyboard_simulator.dart';
import '../../powershell_runner.dart';
import '../../input_simulator.dart'; // For InputSimulator.onCommandError
import '../../presenter_settings.dart';
import 'presenter_com.dart';

/// PowerPoint and WPS Presentation: the same COM object model and mostly the
/// same slideshow keys. [PresenterCom.lookup] finds the running one.
class PptController {
  static bool _isLaserActive = false;

  // PpSlideShowPointerType, shared by PowerPoint and WPS.
  static const pointerArrow = 1;
  static const pointerPen = 2;
  static const pointerAutoArrow = 4;
  static const pointerEraser = 5;

  static Future<void> slideNext() async {
    await _clearInkBeforeMove();
    KeyboardSimulator.pressKey(VK_NEXT);
  }

  static Future<void> slidePrev() async {
    await _clearInkBeforeMove();
    KeyboardSimulator.pressKey(VK_PRIOR);
  }

  /// PowerPoint and WPS keep a slide's ink and show it again when the show
  /// comes back. With the setting on, the ink is erased first: in PowerPoint
  /// with E, but only in the slideshow window ('screenClass') since in the
  /// editor it would type an E; in WPS through COM.
  static Future<void> _clearInkBeforeMove() async {
    if (!PresenterSettings.clearInkOnSlideChange) return;
    final hwnd = GetForegroundWindow();
    final exe = _windowExecutable(hwnd);
    if (exe.endsWith(r'\wpp.exe')) {
      await _eraseDrawingCom();
      return;
    }
    final classNamePtr = wsalloc(256);
    GetClassName(hwnd, classNamePtr, 256);
    final className = classNamePtr.toDartString();
    free(classNamePtr);
    if (className == 'screenClass' && exe.endsWith(r'\powerpnt.exe')) {
      KeyboardSimulator.pressKey(0x45); // E
    }
  }

  /// Runs [body] on the running show's view (`$view`) and returns its output:
  /// "NO_SLIDESHOW" when no show runs, "ERROR: ..." when COM fails.
  static Future<String> _onShow(String body) async {
    final script = '${PresenterCom.lookup}'
        r'''
try {
    if ($ppt -ne $null -and $ppt.SlideShowWindows.Count -gt 0) {
        $view = $ppt.SlideShowWindows.Item(1).View
'''
        '$body\n'
        r'''
    } else {
        Write-Output "NO_SLIDESHOW"
    }
} catch {
    Write-Output "ERROR: $($_.Exception.Message)"
}
''';
    try {
      return (await PowerShellRunner.execute(script)).trim();
    } catch (e) {
      return 'ERROR: $e';
    }
  }

  /// Erases the running show's ink through COM. Returns whether it did.
  static Future<bool> _eraseDrawingCom() async {
    final result = await _onShow(r'''
        $view.EraseDrawing()
        Write-Output "OK"''');
    if (result != 'OK') debugPrint('EraseDrawing: $result');
    return result == 'OK';
  }

  static Future<void> slideStart() async {
    try {
      final script = '${PresenterCom.lookup}'
          r'''
try {
    if ($ppt -ne $null -and $qrPresenter -eq 'powerpoint' -and $ppt.ActiveProtectedViewWindow -ne $null) {
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
    // Both PowerPoint and WPS start the show from the first slide with F5.
    KeyboardSimulator.pressKey(VK_F5);
  }

  /// Starts the show and jumps to [slideNumber] through COM. Typing the
  /// number + Enter (PowerPoint's own shortcut) would land in whatever window
  /// has the focus when the show did not open.
  static Future<void> slideStartAt(int slideNumber) async {
    await slideStart();
    // The lookup runs again on every try: with PowerPoint and WPS both open,
    // the one whose show F5 opened is known only once the show is up.
    // $slideNumber is an int validated by CommandRouter (1..9999).
    final script = r'''
try {
    for ($qrTry = 0; $qrTry -lt 20; $qrTry++) {
'''
        '${PresenterCom.lookup}'
        r'''
        if ($ppt -ne $null -and $ppt.SlideShowWindows.Count -gt 0) { break }
        Start-Sleep -Milliseconds 100
    }
    if ($ppt -eq $null -or $ppt.SlideShowWindows.Count -eq 0) {
        Write-Output "NOT_READY"
    } else {
        $view = $ppt.SlideShowWindows.Item(1).View
        $total = $ppt.SlideShowWindows.Item(1).Presentation.Slides.Count
'''
        '        \$view.GotoSlide([Math]::Min($slideNumber, \$total))\n'
        r'''
        Write-Output "OK"
    }
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
    if ((className == '#32770' || className == 'NUIDialog') &&
        _windowExecutable(hwnd).endsWith(r'\powerpnt.exe')) {
      KeyboardSimulator.pressKey(VK_TAB);
      await Future.delayed(const Duration(milliseconds: 50));
      KeyboardSimulator.pressKey(VK_RETURN);
    }
  }

  /// Lower-case path of the program owning [hwnd], or '' when unknown.
  static String _windowExecutable(HWND hwnd) {
    final pid = calloc<Uint32>();
    final size = calloc<Uint32>()..value = 1024;
    final path = wsalloc(1024);
    try {
      GetWindowThreadProcessId(hwnd, pid);
      final process = OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION, false, pid.value).value;
      if (process.address == 0) return '';
      try {
        if (!QueryFullProcessImageName(process, PROCESS_NAME_WIN32, path, size).value) return '';
        return path.toDartString().toLowerCase();
      } finally {
        CloseHandle(process);
      }
    } finally {
      calloc.free(pid);
      calloc.free(size);
      free(path);
    }
  }

  static bool _isPresenterWindow(HWND hwnd) {
    final exe = _windowExecutable(hwnd);
    return PresenterCom.executables.any(exe.endsWith);
  }

  static Future<void> blackScreen() => pressInSlideShow([0x42]); // B
  static Future<void> whiteScreen() => pressInSlideShow([0x57]); // W

  static Future<void> eraseAllInk() async {
    if (PresenterCom.wpsActive) {
      if (!await _eraseDrawingCom()) InputSimulator.onCommandError?.call('Mürekkep silinemedi.');
      return;
    }
    await pressInSlideShow([0x45]); // E
  }

  static Future<void> toggleLaserCursor() async {
    final laser = !_isLaserActive;
    if (PresenterCom.wpsActive) {
      // WPS has no laser: the visible arrow follows the phone instead.
      if (await setPointerType(laser ? pointerArrow : pointerAutoArrow)) _isLaserActive = laser;
      return;
    }
    if (await pressInSlideShow([VK_CONTROL, laser ? 0x4C : 0x41])) _isLaserActive = laser;
  }

  /// Presses a slideshow shortcut only while PowerPoint or WPS has the focus,
  /// bringing its slideshow window forward when another window has it.
  /// Ctrl+A, B, E, ... in a focused Word window would select all and
  /// replace the text. Returns whether the keys were sent.
  static Future<bool> pressInSlideShow(List<int> keys) async {
    if (!_isPresenterWindow(GetForegroundWindow()) && !await _focusPptSlideShow()) {
      debugPrint('Slideshow shortcut skipped: no presentation program has the focus');
      return false;
    }
    KeyboardSimulator.pressKeyCombo(keys);
    return true;
  }

  static void setLaserActive(bool active) {
    _isLaserActive = active;
  }

  /// Sets the show's pointer (PpSlideShowPointerType) through COM, which
  /// needs no focus. Returns whether it did.
  static Future<bool> setPointerType(int type) async {
    final result = await _onShow('''
        \$view.PointerType = $type
        Write-Output "OK"''');
    if (result == 'OK') return true;
    debugPrint('setPointerType($type): $result');
    InputSimulator.onCommandError
        ?.call(result == 'NO_SLIDESHOW' ? 'Slayt gösterisi aktif değil.' : 'Sunum programına ulaşılamadı.');
    return false;
  }

  /// Sets the ink color of the running show's pen (or of the highlighter,
  /// while it is the active tool).
  static Future<void> setPointerColor(int bgrColor) async {
    final output = await _onShow('''
        \$view.PointerColor.RGB = $bgrColor
        Write-Output "OK"''');
    debugPrint('setPointerColor output: $output');
    if (output == 'OK') return;
    String errorMsg;
    if (output == 'NO_SLIDESHOW') {
      errorMsg = 'Slayt gösterisi aktif değil.';
    } else if (output.contains('0x800706BA') || output.contains('RPC server is unavailable')) {
      errorMsg = 'Sunum programı yanıt vermiyor.';
    } else {
      errorMsg = 'Kalem rengi değiştirilemedi.';
    }
    debugPrint('setPointerColor failed: $output');
    InputSimulator.onCommandError?.call(errorMsg);
  }

  static Future<bool> _focusPptSlideShow() async {
    final hwndScript = '${PresenterCom.lookup}'
        r'''
try {
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
  /// through COM. When COM can't reach one in PowerPoint, focuses the
  /// slideshow, selects the media with Tab and presses [fallbackKeys]
  /// (PowerPoint's media keys).
  static Future<void> _pptMedia({
    required String name,
    required String playerAction,
    required List<int> fallbackKeys,
  }) async {
    final comScript = '${PresenterCom.lookup}'
        r'''
try {
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
                # Media (16), or a placeholder holding media (14 + ContainedType 16).
                $isMedia = $shape.Type -eq 16
                if (-not $isMedia -and $shape.Type -eq 14) {
                    try { $isMedia = $shape.PlaceholderFormat.ContainedType -eq 16 } catch {}
                }
                if (-not $isMedia) { continue }
                $player = $null
                try { $player = $view.Player($shape.Name) } catch {}
                if ($player -eq $null) { try { $player = $view.Player($shape.Id) } catch {} }
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
        Write-Output "COM_FAIL_$($qrPresenter)_$slideNum"
    }
} catch {
    Write-Output "ERROR: $($_.Exception.Message)"
}
'''.replaceFirst('__PLAYER_ACTION__', playerAction);
    try {
      final result = (await PowerShellRunner.execute(comScript)).trim();
      if (result == 'NO_SLIDESHOW' || result.startsWith('COM_OK_')) return;
      if (result.startsWith('COM_FAIL_wps_')) {
        InputSimulator.onCommandError?.call('Bu slayttaki medya kumandadan kontrol edilemiyor.');
        return;
      }

      final focused = await _focusPptSlideShow();
      if (!focused) return;

      // Alt+P / Alt+Home act only on a selected media shape, and the
      // selection does not survive (a click, the pen, the last Alt+P), so
      // select it with Tab every time. Skipping Tab after the first press on
      // a slide left the video playing.
      KeyboardSimulator.pressKey(VK_TAB);
      await Future.delayed(const Duration(milliseconds: 200));
      KeyboardSimulator.pressKeyCombo(fallbackKeys);
    } catch (e) {
      debugPrint('$name error: $e');
    }
  }
}
