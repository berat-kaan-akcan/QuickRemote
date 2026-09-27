import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'keyboard_simulator.dart';
import '../../powershell_runner.dart';

class VolumeController {
  static const String _audioControlCSharp =
      '''using System; using System.Runtime.InteropServices; namespace AudioControl { [Guid("5CDF2C82-841E-4546-9722-0CF74078229A"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)] public interface IAudioEndpointVolume { int RegisterControlChangeNotify(IntPtr pNotify); int UnregisterControlChangeNotify(IntPtr pNotify); int GetChannelCount(out uint pnChannelCount); int SetMasterVolumeLevel(float fLevelDB, System.Guid pguidEventContext); int SetMasterVolumeLevelScalar(float fLevel, System.Guid pguidEventContext); int GetMasterVolumeLevel(out float pfLevelDB); int GetMasterVolumeLevelScalar(out float pfLevel); int SetChannelVolumeLevel(uint nChannel, float fLevelDB, System.Guid pguidEventContext); int SetChannelVolumeLevelScalar(uint nChannel, float fLevel, System.Guid pguidEventContext); int GetChannelVolumeLevel(uint nChannel, out float pfLevelDB); int GetChannelVolumeLevelScalar(uint nChannel, out float pfLevel); int SetMute([MarshalAs(UnmanagedType.Bool)] bool bMute, System.Guid pguidEventContext); int GetMute([MarshalAs(UnmanagedType.Bool)] out bool pbMute); } [Guid("D666063F-1587-4E43-81F1-B948E807363F"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)] public interface IMMDevice { int Activate(ref System.Guid iid, int dwClsCtx, IntPtr pActivationParams, [MarshalAs(UnmanagedType.IUnknown)] out object ppInterface); } [Guid("A95664D2-9614-4F35-A746-DE8DB63617E6"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)] public interface IMMDeviceEnumerator { int NotImpl1(); int GetDefaultAudioEndpoint(int dataFlow, int role, out IMMDevice ppDevice); } [ComImport, Guid("BCDE0395-E52F-467C-8E3D-C4579291692E")] public class MMDeviceEnumerator {} public class Audio { public static IAudioEndpointVolume GetVolumeObject() { IMMDeviceEnumerator enumerator = (IMMDeviceEnumerator)(new MMDeviceEnumerator()); IMMDevice device; enumerator.GetDefaultAudioEndpoint(0, 1, out device); Guid iid = new Guid("5CDF2C82-841E-4546-9722-0CF74078229A"); object obj; device.Activate(ref iid, 23, IntPtr.Zero, out obj); return (IAudioEndpointVolume)obj; } public static void SetVolume(float level) { GetVolumeObject().SetMasterVolumeLevelScalar(level, Guid.Empty); } public static float GetVolume() { float level; GetVolumeObject().GetMasterVolumeLevelScalar(out level); return level; } public static void SetMute(bool mute) { GetVolumeObject().SetMute(mute, Guid.Empty); } public static bool GetMute() { bool mute; GetVolumeObject().GetMute(out mute); return mute; } } }''';

  static String getAudioControlPSScript() {
    final b64 = base64Encode(utf8.encode(_audioControlCSharp));
    return '''
    if (-not ("AudioControl.Audio" -as [type])) {
        \$b = [System.Convert]::FromBase64String("$b64")
        \$c = [System.Text.Encoding]::UTF8.GetString(\$b)
        Add-Type -ErrorAction Stop -TypeDefinition \$c
    }''';
  }

  static void volumeUp() => KeyboardSimulator.pressKey(0xAF);
  static void volumeDown() => KeyboardSimulator.pressKey(0xAE);
  static void volumeMute() => KeyboardSimulator.pressKey(0xAD);

  static Future<void> setVolume(int level) async {
    final clamped = level.clamp(0, 100);
    final script =
        '''
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
      await PowerShellRunner.execute(script);
    } catch (e) {
      debugPrint('setVolume error: $e');
    }
  }
}
