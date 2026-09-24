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

    final isExtended = (vkCode >= 0xAE && vkCode <= 0xB3) ||
                       vkCode == VK_NEXT || vkCode == VK_PRIOR || 
                       vkCode == VK_HOME || vkCode == VK_END ||
                       vkCode == VK_LEFT || vkCode == VK_UP || 
                       vkCode == VK_RIGHT || vkCode == VK_DOWN ||
                       vkCode == VK_INSERT || vkCode == VK_DELETE;
    final int extFlag = isExtended ? 0x0001 : 0; // KEYEVENTF_EXTENDEDKEY = 0x0001

    // Key down
    inputs[0].type = INPUT_KEYBOARD;
    inputs[0].ki.wVk = VIRTUAL_KEY(vkCode);
    inputs[0].ki.dwFlags = KEYBD_EVENT_FLAGS(extFlag); // was KEYBD_EVENT_FLAGS(0)

    // Key up
    inputs[1].type = INPUT_KEYBOARD;
    inputs[1].ki.wVk = VIRTUAL_KEY(vkCode);
    inputs[1].ki.dwFlags = KEYBD_EVENT_FLAGS(KEYEVENTF_KEYUP | extFlag);

    SendInput(2, inputs, sizeOf<INPUT>());
    calloc.free(inputs);
  }

  /// Simulate a key combination (e.g., Win+L).
  static void pressKeyCombo(List<int> vkCodes) {
    final count = vkCodes.length * 2;
    final inputs = calloc<INPUT>(count);

    // All keys down
    for (var i = 0; i < vkCodes.length; i++) {
      final vk = vkCodes[i];
      final isExtended = (vk >= 0xAE && vk <= 0xB3) ||
                         vk == VK_NEXT || vk == VK_PRIOR || 
                         vk == VK_HOME || vk == VK_END ||
                         vk == VK_LEFT || vk == VK_UP || 
                         vk == VK_RIGHT || vk == VK_DOWN ||
                         vk == VK_INSERT || vk == VK_DELETE;
      final int extFlag = isExtended ? 0x0001 : 0;

      inputs[i].type = INPUT_KEYBOARD;
      inputs[i].ki.wVk = VIRTUAL_KEY(vk);
      inputs[i].ki.dwFlags = KEYBD_EVENT_FLAGS(extFlag);
    }

    // All keys up (reverse order)
    for (var i = 0; i < vkCodes.length; i++) {
      final idx = vkCodes.length + i;
      final vk = vkCodes[vkCodes.length - 1 - i];
      final isExtended = (vk >= 0xAE && vk <= 0xB3) ||
                         vk == VK_NEXT || vk == VK_PRIOR || 
                         vk == VK_HOME || vk == VK_END ||
                         vk == VK_LEFT || vk == VK_UP || 
                         vk == VK_RIGHT || vk == VK_DOWN ||
                         vk == VK_INSERT || vk == VK_DELETE;
      final int extFlag = isExtended ? 0x0001 : 0;

      inputs[idx].type = INPUT_KEYBOARD;
      inputs[idx].ki.wVk = VIRTUAL_KEY(vk);
      inputs[idx].ki.dwFlags = KEYBD_EVENT_FLAGS(KEYEVENTF_KEYUP | extFlag);
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

  /// Black screen (B key)
  static void blackScreen() => pressKey(0x42);

  /// White screen (W key)
  static void whiteScreen() => pressKey(0x57);

  /// Erase all ink annotations on current slide (E key in PowerPoint slideshow)
  static void eraseAllInk() => pressKey(0x45);

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



  // ─── Ses kontrolü ───────────────────────────────────────────────────

  static const String _audioControlCSharp = '''using System; using System.Runtime.InteropServices; namespace AudioControl { [Guid("5CDF2C82-841E-4546-9722-0CF74078229A"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)] public interface IAudioEndpointVolume { int RegisterControlChangeNotify(IntPtr pNotify); int UnregisterControlChangeNotify(IntPtr pNotify); int GetChannelCount(out uint pnChannelCount); int SetMasterVolumeLevel(float fLevelDB, System.Guid pguidEventContext); int SetMasterVolumeLevelScalar(float fLevel, System.Guid pguidEventContext); int GetMasterVolumeLevel(out float pfLevelDB); int GetMasterVolumeLevelScalar(out float pfLevel); int SetChannelVolumeLevel(uint nChannel, float fLevelDB, System.Guid pguidEventContext); int SetChannelVolumeLevelScalar(uint nChannel, float fLevel, System.Guid pguidEventContext); int GetChannelVolumeLevel(uint nChannel, out float pfLevelDB); int GetChannelVolumeLevelScalar(uint nChannel, out float pfLevel); int SetMute([MarshalAs(UnmanagedType.Bool)] bool bMute, System.Guid pguidEventContext); int GetMute([MarshalAs(UnmanagedType.Bool)] out bool pbMute); } [Guid("D666063F-1587-4E43-81F1-B948E807363F"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)] public interface IMMDevice { int Activate(ref System.Guid iid, int dwClsCtx, IntPtr pActivationParams, [MarshalAs(UnmanagedType.IUnknown)] out object ppInterface); } [Guid("A95664D2-9614-4F35-A746-DE8DB63617E6"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)] public interface IMMDeviceEnumerator { int NotImpl1(); int GetDefaultAudioEndpoint(int dataFlow, int role, out IMMDevice ppDevice); } [ComImport, Guid("BCDE0395-E52F-467C-8E3D-C4579291692E")] public class MMDeviceEnumerator {} public class Audio { public static IAudioEndpointVolume GetVolumeObject() { IMMDeviceEnumerator enumerator = (IMMDeviceEnumerator)(new MMDeviceEnumerator()); IMMDevice device; enumerator.GetDefaultAudioEndpoint(0, 1, out device); Guid iid = new Guid("5CDF2C82-841E-4546-9722-0CF74078229A"); object obj; device.Activate(ref iid, 23, IntPtr.Zero, out obj); return (IAudioEndpointVolume)obj; } public static void SetVolume(float level) { GetVolumeObject().SetMasterVolumeLevelScalar(level, Guid.Empty); } public static float GetVolume() { float level; GetVolumeObject().GetMasterVolumeLevelScalar(out level); return level; } public static void SetMute(bool mute) { GetVolumeObject().SetMute(mute, Guid.Empty); } public static bool GetMute() { bool mute; GetVolumeObject().GetMute(out mute); return mute; } } }''';

  /// PowerShell'de AudioControl.Audio sınıfını tanımlayan betik parçasını döndürür.
  /// Base64 üzerinden C# kodunu okuyup Add-Type ile yükler (powershell çok satırlı stdin hatalarını aşar).
  static String getAudioControlPSScript() {
    final b64 = base64Encode(utf8.encode(_audioControlCSharp));
    return '''
    if (-not ("AudioControl.Audio" -as [type])) {
        \$b = [System.Convert]::FromBase64String("$b64")
        \$c = [System.Text.Encoding]::UTF8.GetString(\$b)
        Add-Type -ErrorAction Stop -TypeDefinition \$c
    }''';
  }

  /// Sistem sesini bir adım artır (VK_VOLUME_UP)
  static void volumeUp()   => pressKey(0xAF);

  /// Sistem sesini bir adım azalt (VK_VOLUME_DOWN)
  static void volumeDown() => pressKey(0xAE);

  /// Sistemi mute/unmute yap (VK_VOLUME_MUTE)
  static void volumeMute() => pressKey(0xAD);

  /// Windows varsayılan ses cihazının seviyesini 0-100 arasında ayarla.
  /// PowerShell CoreAudio COM arayüzü kullanır — harici araç gerektirmez.
  static Future<void> setVolume(int level) async {
    final clamped = level.clamp(0, 100);
    // IMMDeviceEnumerator / IAudioEndpointVolume COM arayüzü
    final script = '''
\$vol = [float]$clamped / 100.0
try {
${getAudioControlPSScript()}
    [AudioControl.Audio]::SetVolume(\$vol)
} catch {
    Write-Output \$_.Exception.Message
}
Write-Output "OK"
''';
    try {
      await _PowerShellRunner.execute(script);
    } catch (e) {
      debugPrint('setVolume error: $e');
    }
  }

  // ─── PPT gömülü video kontrolü ──────────────────────────────────────

  /// PowerPoint SlideShow penceresine focus ver (Win32 API).
  /// HWND'yi PowerShell COM'dan alıp, Dart FFI ile focus ayarlar.
  /// Dönüş: true = focus başarılı, false = başarısız.
  static Future<bool> _focusPptSlideShow() async {
    // PowerShell ile SlideShow HWND'sini al
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
      final hwndStr = (await _PowerShellRunner.execute(hwndScript)).trim();
      final hwndVal = int.tryParse(hwndStr) ?? 0;
      if (hwndVal == 0) return false;

      final hwnd = HWND(Pointer.fromAddress(hwndVal));

      // Win32 API ile focus ayarla. SendInput her zaman o anki ön plan
      // penceresine gider; bu nedenle aşağıda odağın gerçekten Slideshow
      // penceresine geçtiğini ayrıca doğruluyoruz.
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

      // Slideshow penceresini restore etmek, tam ekran sunumu küçültebilir.
      // Yalnızca görünür durumdaysa üstte/önde tutmak yeterlidir.
      BringWindowToTop(hwnd);
      SetForegroundWindow(hwnd);

      if (attached1) AttachThreadInput(curThread, foreThread, false);
      if (attached2) AttachThreadInput(curThread, targetThread, false);

      // Focus'un yerleşmesi için kısa bekleme. SetForegroundWindow'un dönüşü,
      // odağın gerçekten değiştiğini garanti etmez (Windows foreground lock).
      await Future.delayed(const Duration(milliseconds: 200));
      return GetForegroundWindow() == hwnd;
    } catch (e) {
      debugPrint('_focusPptSlideShow error: $e');
      return false;
    }
  }

  /// PowerPoint sunum modunda gömülü videoyu Oynat/Durdur.
  ///
  /// Strateji sırası:
  /// 1. COM MediaPlayer.Play()/Pause() — en güvenilir, focus gerektirmez
  /// 2. Win32 SendInput — focus + Tab + Alt+P doğrudan donanım düzeyinde
  ///
  /// Önceki sürümde PowerShell SendKeys kullanılıyordu ama bu Windows
  /// System Media Transport Controls (SMTC) tarafından yakalanıp
  /// Chrome'daki videoyu durduruyordu. SendInput bunu yapmaz.
  static Future<void> pptMediaPlayPause() async {
    // ── Strateji 1: COM ile doğrudan medya kontrolü ──
    const comScript = r'''
try {
    $ppt = [System.Runtime.InteropServices.Marshal]::GetActiveObject("PowerPoint.Application")
    if ($ppt -eq $null -or $ppt.SlideShowWindows.Count -eq 0) {
        Write-Output "NO_SLIDESHOW"
        return
    }

    $view  = $ppt.SlideShowWindows.Item(1).View
    $slide = $view.Slide

    $mediaControlled = $false
    try {
        # Video nesneleri Office sürümüne/ekleme şekline göre farklı Shape.Type
        # değerleri kullanabilir. Player() çağrısı medya olmayan şekillerde hata
        # verir; onu yakalayarak tüm şekilleri güvenle tarıyoruz.
        # Player() metodu Shape'in Name string'ini bekler, Id integer'ını değil.
        for ($i = 1; $i -le $slide.Shapes.Count; $i++) {
            try {
                $shape = $slide.Shapes.Item($i)
                $player = $view.Player($shape.Name)
                if ($player -ne $null) {
                    # PpPlayerState: ppPlaying = 0, ppPaused = 1,
                    # ppStopped = 2, ppMediaEnded = 3.
                    # Oynuyorsa duraklat, aksi halde oynat.
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
        Write-Output "COM_OK"
    } else {
        Write-Output "COM_FAIL"
    }
} catch {
    Write-Output "ERROR: $($_.Exception.Message)"
}
''';
    try {
      final result = (await _PowerShellRunner.execute(comScript)).trim();
      debugPrint('pptMediaPlayPause COM: $result');

      if (result == 'COM_OK') return;
      if (result == 'NO_SLIDESHOW') return;

      // ── Strateji 2: Win32 SendInput ile Tab + Space ──
      // Focus'u PPT SlideShow penceresine ver
      final focused = await _focusPptSlideShow();
      debugPrint('pptMediaPlayPause focus: $focused');

      // Odağı alamadıysak tuş gönderme: aksi halde Chrome/YouTube gibi
      // ön plandaki uygulama bu kısayolu alır.
      if (!focused) {
        debugPrint('pptMediaPlayPause: slideshow focus unavailable; keyboard fallback skipped');
        return;
      }

      // Tab tuşu — medya nesnesini seç
      pressKey(VK_TAB);
      await Future.delayed(const Duration(milliseconds: 200));

      // Space — seçili medyayı oynat/durdur
      // (PowerPoint sunum modunda video seçiliyken Space toggle yapar)
      pressKey(VK_SPACE);

      debugPrint('pptMediaPlayPause: SENDINPUT_OK (focused=$focused)');
    } catch (e) {
      debugPrint('pptMediaPlayPause error: $e');
    }
  }

  /// Aktif slaytta gömülü videoyu başa sar.
  ///
  /// Strateji:
  /// 1. COM Otomasyon: MediaPlayer.CurrentPosition = 0
  /// 2. Win32 SendInput: Focus + Tab + Alt+Home (donanım düzeyinde)
  static Future<void> pptMediaRewind() async {
    // ── Strateji 1: COM ile başa sar ──
    const comScript = r'''
try {
    $ppt = [System.Runtime.InteropServices.Marshal]::GetActiveObject("PowerPoint.Application")
    if ($ppt -eq $null -or $ppt.SlideShowWindows.Count -eq 0) {
        Write-Output "NO_SLIDESHOW"
        return
    }

    $view  = $ppt.SlideShowWindows.Item(1).View
    $slide = $view.Slide

    $mediaControlled = $false
    try {
        # Player() metodu Shape'in Name string'ini bekler.
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
        Write-Output "COM_OK"
    } else {
        Write-Output "COM_FAIL"
    }
} catch {
    Write-Output "ERROR: $($_.Exception.Message)"
}
''';
    try {
      final result = (await _PowerShellRunner.execute(comScript)).trim();
      debugPrint('pptMediaRewind COM: $result');

      if (result == 'COM_OK') return;
      if (result == 'NO_SLIDESHOW') return;

      // ── Strateji 2: Win32 SendInput ile Tab + Home ──
      final focused = await _focusPptSlideShow();
      debugPrint('pptMediaRewind focus: $focused');

      if (!focused) {
        debugPrint('pptMediaRewind: slideshow focus unavailable; keyboard fallback skipped');
        return;
      }

      // Tab tuşu — medya nesnesini seç
      pressKey(VK_TAB);
      await Future.delayed(const Duration(milliseconds: 200));

      // Home — seçili medyayı başa sar
      // (Alt olmadan Home tuşu video timeline'ı başa sarar)
      pressKey(VK_HOME);

      debugPrint('pptMediaRewind: SENDINPUT_OK (focused=$focused)');
    } catch (e) {
      debugPrint('pptMediaRewind error: $e');
    }
  }

  // ─── Sistem medya transport ──────────────────────────────────────────

  /// Aktif medya uygulamasını Oynat/Durdur (VK_MEDIA_PLAY_PAUSE)
  static void sysMediaPlayPause() => pressKey(0xB3);

  /// Sonraki parçaya geç (VK_MEDIA_NEXT_TRACK)
  static void sysMediaNext() => pressKey(0xB0);

  /// Önceki parçaya geç (VK_MEDIA_PREV_TRACK)
  static void sysMediaPrev() => pressKey(0xB1);

  /// Medyayı durdur (VK_MEDIA_STOP)
  static void sysMediaStop() => pressKey(0xB2);

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

    if (command.startsWith('VOLUME_SET:')) {
      final levelStr = command.split(':')[1];
      final level = int.tryParse(levelStr);
      if (level != null && level >= 0 && level <= 100) {
        setVolume(level);
      } else {
        debugPrint('Invalid VOLUME_SET value: $levelStr (must be 0-100)');
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
      case 'BLACK_SCREEN':
        blackScreen();
        break;
      case 'WHITE_SCREEN':
        whiteScreen();
        break;
      case 'ERASE_ALL':
        eraseAllInk();
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

      // ── Ses kontrolü ──
      case 'VOLUME_UP':
        volumeUp();
        break;
      case 'VOLUME_DOWN':
        volumeDown();
        break;
      case 'VOLUME_MUTE':
        volumeMute();
        break;

      // ── PPT gömülü video ──
      case 'MEDIA_PLAY_PAUSE':
        pptMediaPlayPause();
        break;
      case 'MEDIA_REWIND':
        pptMediaRewind();
        break;

      // ── Sistem medya transport ──
      case 'SYSTEM_MEDIA_PLAY_PAUSE':
        sysMediaPlayPause();
        break;
      case 'SYSTEM_MEDIA_NEXT':
        sysMediaNext();
        break;
      case 'SYSTEM_MEDIA_PREV':
        sysMediaPrev();
        break;
      case 'SYSTEM_MEDIA_STOP':
        sysMediaStop();
        break;

      default:
        debugPrint('Unknown command: $command');
    }
  }

  /// Get current slide state (current slide, total slides, notes)
  static String getSmtcStatePSScript() {
    return '''
try {
    \$managerType = [Windows.Media.Control.GlobalSystemMediaTransportControlsSessionManager, Windows.Media, ContentType=WindowsRuntime]
    \$asyncOp = \$managerType::RequestAsync()

    Add-Type -AssemblyName System.Runtime.WindowsRuntime

    \$asTaskGeneric = ([System.WindowsRuntimeSystemExtensions].GetMethods() | Where-Object { 
        \$_.Name -eq 'AsTask' -and \$_.GetParameters().Count -eq 1 -and \$_.GetParameters()[0].ParameterType.Name -eq 'IAsyncOperation`1' 
    })[0]

    \$asTask = \$asTaskGeneric.MakeGenericMethod(\$managerType)
    \$netTask = \$asTask.Invoke(\$null, @(\$asyncOp))
    if (-not \$netTask.Wait(2000)) { throw "Timeout" }
    \$manager = \$netTask.Result

    \$session = \$manager.GetCurrentSession()
    if (\$session -ne \$null) {
        \$propsAsync = \$session.TryGetMediaPropertiesAsync()
        
        \$propsType = [Windows.Media.Control.GlobalSystemMediaTransportControlsSessionMediaProperties, Windows.Media, ContentType=WindowsRuntime]
        \$asTask2 = \$asTaskGeneric.MakeGenericMethod(\$propsType)
        \$netTask2 = \$asTask2.Invoke(\$null, @(\$propsAsync))
        if (-not \$netTask2.Wait(2000)) { throw "Timeout" }
        \$props = \$netTask2.Result
        
        [Console]::OutputEncoding = [System.Text.Encoding]::UTF8

        \$posMs = 0
        \$durMs = 0
        \$isPlaying = \$false
        try {
            \$tl = \$session.GetTimelineProperties()
            \$posMs = [int64]\$tl.Position.TotalMilliseconds
            \$durMs = [int64]\$tl.EndTime.TotalMilliseconds
            \$lastUpdated = \$tl.LastUpdatedTime
            
            \$playbackInfo = \$session.GetPlaybackInfo()
            if (\$playbackInfo -ne \$null) {
                \$isPlaying = (\$playbackInfo.PlaybackStatus -eq [Windows.Media.Control.GlobalSystemMediaTransportControlsSessionPlaybackStatus]::Playing)
            }

            if (\$isPlaying -and \$lastUpdated -ne \$null) {
                \$now = [System.DateTimeOffset]::UtcNow
                \$diff = \$now - \$lastUpdated
                \$posMs += [int64]\$diff.TotalMilliseconds
            }
        } catch {}
        
        \$thumbBase64 = ""
        if (\$props.Thumbnail -ne \$null) {
            try {
                \$thumbAsync = \$props.Thumbnail.OpenReadAsync()
                \$asTaskStream = \$asTaskGeneric.MakeGenericMethod([Windows.Storage.Streams.IRandomAccessStreamWithContentType])
                \$netTaskStream = \$asTaskStream.Invoke(\$null, @(\$thumbAsync))
                if (-not \$netTaskStream.Wait(2000)) { throw "Timeout" }
                \$stream = \$netTaskStream.Result

                \$asStreamMethod = ([System.IO.WindowsRuntimeStreamExtensions].GetMethods() | Where-Object { \$_.Name -eq 'AsStreamForRead' -and \$_.GetParameters().Count -eq 1 })[0]
                \$dotNetStream = \$asStreamMethod.Invoke(\$null, @(\$stream))

                \$memoryStream = New-Object System.IO.MemoryStream
                \$dotNetStream.CopyTo(\$memoryStream)
                \$thumbBase64 = [Convert]::ToBase64String(\$memoryStream.ToArray())

                \$dotNetStream.Close()
                \$memoryStream.Close()
            } catch {}
        }
        
        \$data = @{
            hasMedia = \$true
            title = \$props.Title
            artist = \$props.Artist
            positionMs = \$posMs
            durationMs = \$durMs
            isPlaying = \$isPlaying
            thumbnail = \$thumbBase64
        }
        \$data | ConvertTo-Json -Compress
    } else {
        Write-Output '{"hasMedia": false}'
    }
} catch {
    \$msg = \$_.Exception.Message
    \$data = @{
        hasMedia = \$false
        error = \$msg
    }
    \$data | ConvertTo-Json -Compress
}
''';
  }

  static Future<Map<String, dynamic>?> getSmtcState() async {
    try {
      final output = (await runPowerShellScript(getSmtcStatePSScript())).trim();
      if (output.startsWith('{')) {
        return jsonDecode(output) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint('Error getting SMTC state: \$e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getSlideState() async {
    const script = r'''
try {
    $ppt = [System.Runtime.InteropServices.Marshal]::GetActiveObject("PowerPoint.Application")
    if ($ppt -ne $null -and $ppt.SlideShowWindows.Count -gt 0) {
        $view = $ppt.SlideShowWindows.Item(1).View
        $current = $view.CurrentShowPosition
        $total = $ppt.ActivePresentation.Slides.Count
        
        $isBlackScreen = $false
        if ($current -gt $total) {
            $isBlackScreen = $true
            $current = $total
        }

        $notes = ""
        $hasMedia = $false
        $shapeTypes = ""

        if (-not $isBlackScreen) {
            $slide = $ppt.ActivePresentation.Slides.Item($current)
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

            for ($i = 1; $i -le $slide.Shapes.Count; $i++) {
                try {
                    $s = $slide.Shapes.Item($i)
                    $p = $view.Player($s.Name)
                    if ($p -ne $null) {
                        $hasMedia = $true
                        break
                    }
                } catch {}
            }
            $shapeTypes = ($slide.Shapes | ForEach-Object { "$($_.Name):$($_.Type)" }) -join ", "
        }

        $data = @{
            current = $current
            total = $total
            notes = $notes.Trim()
            hasMedia = $hasMedia
            shapeTypes = $shapeTypes
            isBlackScreen = $isBlackScreen
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

  /// Dış kodun (WebSocketServer gibi) paylasılan PowerShell sürecini kullanabilmesi için
  /// genel amaçlı bir PowerShell script çalıştırıcısı.
  static Future<String> runPowerShellScript(String script) =>
      _PowerShellRunner.execute(script);
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
