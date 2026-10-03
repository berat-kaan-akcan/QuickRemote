import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:win32/win32.dart';
import 'keyboard_simulator.dart';
import 'mouse_simulator.dart';
import '../../powershell_runner.dart';
import '../../input_simulator.dart'; // For InputSimulator.onCommandError
import '../input_service.dart' show RemoteError;
import '../../presenter_settings.dart';
import '../pdf_viewers.dart';
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
    KeyboardSimulator.pressKeyCombo(_viewerInFront()?.next ?? [VK_NEXT]);
  }

  static Future<void> slidePrev() async {
    await _clearInkBeforeMove();
    KeyboardSimulator.pressKeyCombo(_viewerInFront()?.prev ?? [VK_PRIOR]);
  }

  static ViewerKeys? _viewerInFront() =>
      PdfViewers.forProgram(_windowExecutable(GetForegroundWindow()).split(r'\').last);

  /// PowerPoint and WPS keep a slide's ink and show it again when the show
  /// comes back. With the setting on, the ink is erased first: in PowerPoint
  /// with E, in WPS through COM. Only while the show window has the focus:
  /// in the editor the E would be typed.
  static Future<void> _clearInkBeforeMove() async {
    if (!PresenterSettings.clearInkOnSlideChange) return;
    switch (_showWindowKind(GetForegroundWindow())) {
      case 'wps':
        await _eraseDrawingCom();
      case 'powerpoint':
        KeyboardSimulator.pressKey(0x45); // E
    }
  }

  /// 'powerpoint' or 'wps' when [hwnd] is that program's slideshow window,
  /// else null. Measured on PowerPoint 365 (16.0.20430) and WPS 12.2: the
  /// PowerPoint show is a 'screenClass' window; WPS runs its editor in
  /// wps.exe ('PP12FrameClass') and the show in a 'Qt5QWindowIcon' window of
  /// wpp.exe. The editors must not count: B, E or Ctrl+A typed there edit the
  /// slides.
  static String? _showWindowKind(HWND hwnd) {
    final exe = _windowExecutable(hwnd);
    if (exe.endsWith(r'\powerpnt.exe')) return _className(hwnd) == 'screenClass' ? 'powerpoint' : null;
    if (exe.endsWith(r'\wpp.exe')) return _className(hwnd) == 'Qt5QWindowIcon' ? 'wps' : null;
    return null;
  }

  static String _className(HWND hwnd) {
    final name = wsalloc(256);
    try {
      GetClassName(hwnd, name, 256);
      return name.toDartString();
    } finally {
      free(name);
    }
  }

  /// The largest visible slideshow window of [kind] ('powerpoint', 'wps'),
  /// or of either when null. COM gives no handle: SlideShowWindow.HWND is
  /// missing in PowerPoint 365 (DISP_E_MEMBERNOTFOUND) and empty in WPS. The
  /// largest, since WPS's show toolbar may be a window of the same class.
  static HWND? _findShowWindow([String? kind]) {
    final found = <HWND>[];
    int visit(Pointer hwnd, int lParam) {
      final window = HWND(hwnd);
      if (IsWindowVisible(window)) {
        final windowKind = _showWindowKind(window);
        if (windowKind != null && (kind == null || windowKind == kind)) found.add(window);
      }
      return TRUE;
    }

    final callback = NativeCallable<WNDENUMPROC>.isolateLocal(visit, exceptionalReturn: 0);
    try {
      EnumWindows(callback.nativeFunction, LPARAM(0));
    } finally {
      callback.close();
    }
    HWND? best;
    var bestArea = 0;
    final rect = calloc<RECT>();
    try {
      for (final window in found) {
        if (!GetWindowRect(window, rect).value) continue;
        final area = (rect.ref.right - rect.ref.left) * (rect.ref.bottom - rect.ref.top);
        if (area > bestArea) {
          bestArea = area;
          best = window;
        }
      }
    } finally {
      calloc.free(rect);
    }
    return best;
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

  /// The window a START toggled a mode on in (a browser's full screen), and
  /// the keys with which END toggles it off there.
  static (HWND, List<int>)? _toggled;

  /// Presses the start keys of the PDF viewer or browser in front, instead
  /// of F5 (which reloads a browser page). Returns whether it did.
  static bool _startViewer() {
    final hwnd = GetForegroundWindow();
    final viewer = PdfViewers.forProgram(_windowExecutable(hwnd).split(r'\').last);
    if (viewer == null) return false;
    KeyboardSimulator.pressKeyCombo(viewer.start);
    final end = viewer.end;
    _toggled = end == null ? null : (hwnd, end);
    return true;
  }

  static Future<void> slideStart() async {
    if (_startViewer()) return;
    await _startPresenter();
  }

  static Future<void> _startPresenter() async {
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
    // A PDF viewer has no slide to jump to: it starts where it is.
    if (_startViewer()) return;
    await _startPresenter();
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
        InputSimulator.onCommandError?.call(RemoteError.slideshowStartFailed);
      }
    } catch (e) {
      debugPrint('Exception in slideStartAt: $e');
    }
  }

  static Future<void> slideEnd() async {
    final toggled = _toggled;
    _toggled = null;
    if (toggled != null && GetForegroundWindow() == toggled.$1) {
      KeyboardSimulator.pressKeyCombo(toggled.$2);
      return;
    }
    // A show behind another window (its editor, a chat) is brought forward;
    // without one, the Esc is for the program in front (a PDF viewer).
    if (_showWindowKind(GetForegroundWindow()) == null) {
      final show = _findShowWindow();
      if (show != null) await _focusWindow(show);
    }
    // With the pen, highlighter, eraser or laser on, the first Esc only puts
    // the tool away (PowerPoint 365 and WPS 12.2), and in WPS a video clicked
    // to play it takes one more. Esc again while the show is still in front.
    for (var i = 0; i < 3; i++) {
      KeyboardSimulator.pressKey(VK_ESCAPE);
      await Future.delayed(const Duration(milliseconds: 350));
      if (_showWindowKind(GetForegroundWindow()) == null) break;
    }
    final hwnd = GetForegroundWindow();
    final className = _className(hwnd);

    // The "keep ink annotations?" prompt, answered Discard (Tab, Enter) in
    // both: PowerPoint's 'NUIDialog' and WPS's '#32770 (Dialog)' of wpp.exe.
    // '#32770' is the class of every standard dialog, so check the owner too:
    // never answer another application's dialog.
    final exe = _windowExecutable(hwnd);
    if (((className == '#32770' || className == 'NUIDialog') && exe.endsWith(r'\powerpnt.exe')) ||
        (className.startsWith('#32770') && exe.endsWith(r'\wpp.exe'))) {
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

  static Future<void> blackScreen() => pressInSlideShow([0x42]); // B
  static Future<void> whiteScreen() => pressInSlideShow([0x57]); // W

  static Future<void> eraseAllInk() async {
    if (PresenterCom.wpsActive) {
      if (!await _eraseDrawingCom()) InputSimulator.onCommandError?.call(RemoteError.inkEraseFailed);
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

  /// Presses a slideshow shortcut only while the slideshow window has the
  /// focus, bringing it forward when another window has it. Ctrl+A, B, E,
  /// ... in a focused Word window, or in the presentation's own editor, would
  /// select all and replace the text. Returns whether the keys were sent.
  static Future<bool> pressInSlideShow(List<int> keys) async {
    if (!await _focusShow()) {
      debugPrint('Slideshow shortcut skipped: no slideshow window could get the focus');
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
        ?.call(result == 'NO_SLIDESHOW' ? RemoteError.slideshowNotRunning : RemoteError.presenterUnreachable);
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
    RemoteError error;
    if (output == 'NO_SLIDESHOW') {
      error = RemoteError.slideshowNotRunning;
    } else if (output.contains('0x800706BA') || output.contains('RPC server is unavailable')) {
      error = RemoteError.presenterNotResponding;
    } else {
      error = RemoteError.penColorFailed;
    }
    debugPrint('setPointerColor failed: $output');
    InputSimulator.onCommandError?.call(error);
  }

  /// Whether a slideshow window has the focus, after bringing the one of the
  /// program polled last ([PresenterCom.active]) forward when needed.
  static Future<bool> _focusShow() async {
    if (_showWindowKind(GetForegroundWindow()) != null) return true;
    final show = _findShowWindow(PresenterCom.active);
    return show != null && await _focusWindow(show);
  }

  /// Brings [hwnd] to the front from this background process: attached to
  /// the input of the window in front, SetForegroundWindow is allowed
  /// (measured with Notepad in front of a PowerPoint show).
  static Future<bool> _focusWindow(HWND hwnd) async {
    try {
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
      debugPrint('_focusWindow error: $e');
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
        wpsClick: true,
      );

  // Alt+Q (stop) goes back to the start; Alt+Home, the previous bookmark,
  // did nothing on a video without bookmarks (PowerPoint 365).
  static Future<void> pptMediaRewind() => _pptMedia(
        name: 'pptMediaRewind',
        playerAction: r'''
                    $player.Pause()
                    Start-Sleep -Milliseconds 50
                    $player.CurrentPosition = 0''',
        fallbackKeys: [VK_MENU, 0x51], // Alt + Q
        wpsClick: false,
      );

  /// The slide and the time of the slide visit in which Tab selected the
  /// media for the key fallback.
  static (int, DateTime)? _mediaSelected;

  /// Runs [playerAction] on the first media player of the current slide
  /// through COM. When COM can't reach one in PowerPoint, focuses the
  /// slideshow, selects the media with Tab and presses [fallbackKeys]
  /// (PowerPoint's media keys). In WPS, whose Player does nothing (Play()
  /// leaves the video still and State always reads 0, WPS 12.2), a click on
  /// the video toggles it when [wpsClick] is set.
  static Future<void> _pptMedia({
    required String name,
    required String playerAction,
    required List<int> fallbackKeys,
    required bool wpsClick,
  }) async {
    final comScript = '${PresenterCom.lookup}'
        r'''
try {
    if ($ppt -eq $null -or $ppt.SlideShowWindows.Count -eq 0) {
        Write-Output "NO_SLIDESHOW"
    } else {
        $view  = $ppt.SlideShowWindows.Item(1).View
        $slide = $view.Slide
        $result = "NO_MEDIA"
        for ($i = 1; $i -le $slide.Shapes.Count; $i++) {
            try {
                $shape = $slide.Shapes.Item($i)
                # Media (16), or a placeholder holding media (14 + ContainedType 16).
                $isMedia = $shape.Type -eq 16
                if (-not $isMedia -and $shape.Type -eq 14) {
                    try { $isMedia = $shape.PlaceholderFormat.ContainedType -eq 16 } catch {}
                }
                if (-not $isMedia) { continue }
                if ($qrPresenter -eq 'wps') {
                    # The pen would draw where the click lands: the arrow clicks.
                    $pointer = $view.PointerType
                    if ($pointer -eq 2 -or $pointer -eq 5) { $view.PointerType = 1 }
                    $setup = $ppt.SlideShowWindows.Item(1).Presentation.PageSetup
                    $x = $shape.Left + $shape.Width / 2
                    $y = $shape.Top + $shape.Height / 2
                    # String expansion formats numbers with the invariant culture.
                    $result = "WPS_CLICK $x $y $($setup.SlideWidth) $($setup.SlideHeight) $pointer"
                    break
                }
                $player = $null
                try { $player = $view.Player($shape.Name) } catch {}
                if ($player -eq $null) { try { $player = $view.Player($shape.Id) } catch {} }
                if ($player -ne $null) {
__PLAYER_ACTION__
                    $result = "COM_OK"
                    break
                }
                # SlideElapsedTime starts again at every visit of the slide.
                $result = "COM_FAIL $($slide.SlideIndex) $($view.SlideElapsedTime)"
            } catch {}
        }
        Write-Output $result
    }
} catch {
    Write-Output "ERROR: $($_.Exception.Message)"
}
'''.replaceFirst('__PLAYER_ACTION__', playerAction);
    try {
      final result = (await PowerShellRunner.execute(comScript)).trim();
      final parts = result.split(' ');
      switch (parts.first) {
        case 'NO_SLIDESHOW' || 'COM_OK':
          return;
        case 'NO_MEDIA':
          InputSimulator.onCommandError?.call(RemoteError.noMedia);
        case 'WPS_CLICK' when parts.length == 6:
          if (!wpsClick) {
            InputSimulator.onCommandError?.call(RemoteError.wpsNoMediaRewind);
          } else {
            await _clickWpsMedia([for (final p in parts.skip(1).take(4)) double.parse(p)]);
          }
          final pointer = int.parse(parts[5]);
          if (pointer == pointerPen || pointer == pointerEraser) await setPointerType(pointer);
        case 'COM_FAIL' when parts.length == 3:
          await _pptMediaKeys(int.parse(parts[1]), double.parse(parts[2]), fallbackKeys);
        default:
          debugPrint('$name: $result');
      }
    } catch (e) {
      debugPrint('$name error: $e');
    }
  }

  /// PowerPoint's media keys act on the media shape Tab selected. Tab moves
  /// the selection on, so a second Tab on the same visit of the slide
  /// unselects the only video and the keys do nothing; moving the mouse,
  /// clicking, the pen and the keys themselves keep the selection, a slide
  /// change drops it (measured on PowerPoint 365).
  static Future<void> _pptMediaKeys(int slide, double elapsedSeconds, List<int> keys) async {
    if (!await _focusShow()) return;
    final visit = DateTime.now().subtract(Duration(milliseconds: (elapsedSeconds * 1000).round()));
    final selected = _mediaSelected;
    final sameVisit =
        selected != null && selected.$1 == slide && selected.$2.difference(visit).abs() < const Duration(seconds: 1);
    if (!sameVisit) {
      KeyboardSimulator.pressKey(VK_TAB);
      await Future.delayed(const Duration(milliseconds: 200));
      _mediaSelected = (slide, visit);
    }
    KeyboardSimulator.pressKeyCombo(keys);
  }

  /// Clicks the middle of the WPS media shape: [geometry] is its centre and
  /// the slide size, in points. The slide fills the show window, letterboxed.
  static Future<void> _clickWpsMedia(List<double> geometry) async {
    final [x, y, slideWidth, slideHeight] = geometry;
    final show = _findShowWindow('wps');
    if (show == null || slideWidth <= 0 || slideHeight <= 0 || !await _focusWindow(show)) return;
    final rect = calloc<RECT>();
    final cursor = calloc<POINT>();
    try {
      if (!GetWindowRect(show, rect).value) return;
      final width = rect.ref.right - rect.ref.left;
      final height = rect.ref.bottom - rect.ref.top;
      final scale = width / slideWidth < height / slideHeight ? width / slideWidth : height / slideHeight;
      final left = rect.ref.left + (width - slideWidth * scale) / 2;
      final top = rect.ref.top + (height - slideHeight * scale) / 2;
      GetCursorPos(cursor);
      SetCursorPos((left + x * scale).round(), (top + y * scale).round());
      await Future.delayed(const Duration(milliseconds: 50));
      MouseSimulator.leftClick();
      await Future.delayed(const Duration(milliseconds: 50));
      SetCursorPos(cursor.ref.x, cursor.ref.y);
    } finally {
      calloc.free(rect);
      calloc.free(cursor);
    }
  }
}
