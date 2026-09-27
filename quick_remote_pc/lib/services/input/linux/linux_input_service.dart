import 'dart:io';
import 'dart:convert';
import '../input_service.dart';

class LinuxInputService implements InputService {
  @override
  void Function(String detail)? onCommandError;

  @override
  void executeCommand(String command) {
    // Basic dispatcher (some handled by InputSimulator facade directly)
    if (command == 'NEXT') slideNext();
    else if (command == 'PREV') slidePrev();
    else if (command == 'START') slideStart();
    else if (command == 'END') slideEnd();
    else if (command == 'BLACK_SCREEN') blackScreen();
    else if (command == 'WHITE_SCREEN') whiteScreen();
    else if (command == 'LEFT_CLICK') leftClick();
    else if (command == 'RIGHT_CLICK') rightClick();
    else if (command == 'LEFT_DOWN') leftDown();
    else if (command == 'LEFT_UP') leftUp();
    else if (command == 'VOLUME_UP') volumeUp();
    else if (command == 'VOLUME_DOWN') volumeDown();
    else if (command == 'VOLUME_MUTE') volumeMute();
    else if (command == 'MEDIA_PLAY_PAUSE') pptMediaPlayPause();
    else if (command == 'MEDIA_REWIND') pptMediaRewind();
    else if (command == 'SYSTEM_MEDIA_PLAY_PAUSE') sysMediaPlayPause();
    else if (command == 'SYSTEM_MEDIA_NEXT') sysMediaNext();
    else if (command == 'SYSTEM_MEDIA_PREV') sysMediaPrev();
    else if (command == 'SYSTEM_MEDIA_STOP') sysMediaStop();
    else if (command == 'LOCK') lockPC();
  }

  @override
  Future<Map<String, dynamic>?> getSmtcState() async {
    try {
      final result = await Process.run('playerctl', ['metadata']);
      if (result.exitCode != 0) return {'hasMedia': false};

      final statusResult = await Process.run('playerctl', ['status']);
      bool isPlaying = statusResult.stdout.toString().trim().toLowerCase() == 'playing';

      String title = '';
      String artist = '';
      for (var line in result.stdout.toString().split('\n')) {
        if (line.contains('xesam:title')) {
          title = line.split('xesam:title').last.trim();
        } else if (line.contains('xesam:artist')) {
          artist = line.split('xesam:artist').last.trim();
        }
      }

      return {
        'hasMedia': true,
        'title': title,
        'artist': artist,
        'isPlaying': isPlaying,
        'positionMs': 0,
        'durationMs': 0,
        'thumbnail': '',
      };
    } catch (e) {
      return {'hasMedia': false};
    }
  }

  @override
  Future<Map<String, dynamic>?> getSlideState() async {
    return null; // Not easily available for Impress via CLI
  }

  @override
  String getAudioControlPSScript() => '';

  @override
  void volumeUp() => _xdotoolKey('XF86AudioRaiseVolume');

  @override
  void volumeDown() => _xdotoolKey('XF86AudioLowerVolume');

  @override
  void volumeMute() => _xdotoolKey('XF86AudioMute');

  @override
  Future<void> setVolume(int level) async {
    try {
      // Try pactl first (PulseAudio/PipeWire)
      await Process.run('pactl', ['set-sink-volume', '@DEFAULT_SINK@', '${level}%']);
    } catch (e) {
      // Fallback to amixer (ALSA)
      try {
        await Process.run('amixer', ['-D', 'pulse', 'sset', 'Master', '${level}%']);
      } catch (e2) {}
    }
  }

  @override
  void slideNext() => _xdotoolKey('Page_Down');

  @override
  void slidePrev() => _xdotoolKey('Page_Up');

  @override
  Future<void> slideStart() async => _xdotoolKey('F5');

  @override
  Future<void> slideStartAt(int slideNumber) async {
    await slideStart();
    final chars = slideNumber.toString().codeUnits;
    for (final charCode in chars) {
      _xdotoolKey(String.fromCharCode(charCode));
    }
    _xdotoolKey('Return');
  }

  @override
  Future<void> slideEnd() async => _xdotoolKey('Escape');

  @override
  void blackScreen() => _xdotoolKey('b');

  @override
  void whiteScreen() => _xdotoolKey('w');

  @override
  void eraseAllInk() => _xdotoolKey('e');

  @override
  void toggleLaserCursor() {} // Not applicable for Impress

  @override
  Future<void> setPenColor(int bgrColor) async {} // Not applicable for Impress

  @override
  Future<void> pptMediaPlayPause() async => sysMediaPlayPause();

  @override
  Future<void> pptMediaRewind() async {}

  @override
  void leftClick() => _runProcess('xdotool', ['click', '1']);

  @override
  void rightClick() => _runProcess('xdotool', ['click', '3']);

  @override
  void leftDown() => _runProcess('xdotool', ['mousedown', '1']);

  @override
  void leftUp() => _runProcess('xdotool', ['mouseup', '1']);

  @override
  void pressKey(int vkCode) {
    final keyName = _vkToXdotoolKey(vkCode);
    if (keyName != null) {
      _xdotoolKey(keyName);
    }
  }

  @override
  void pressKeyCombo(List<int> vkCodes) {
    final keys = vkCodes.map((vk) => _vkToXdotoolKey(vk)).where((k) => k != null).toList();
    if (keys.isNotEmpty) {
      _runProcess('xdotool', ['key', keys.join('+')]);
    }
  }

  @override
  void lockPC() {
    _runProcess('xdg-screensaver', ['lock']);
  }

  @override
  void sysMediaPlayPause() => _xdotoolKey('XF86AudioPlay');

  @override
  void sysMediaNext() => _xdotoolKey('XF86AudioNext');

  @override
  void sysMediaPrev() => _xdotoolKey('XF86AudioPrev');

  @override
  void sysMediaStop() => _xdotoolKey('XF86AudioStop');

  void _xdotoolKey(String keyName) {
    _runProcess('xdotool', ['key', keyName]);
  }

  void _runProcess(String executable, List<String> args) {
    try {
      Process.run(executable, args);
    } catch (e) {
      print('Error running $executable: $e');
    }
  }

  String? _vkToXdotoolKey(int vkCode) {
    switch (vkCode) {
      case 0x09: return 'Tab';
      case 0x0D: return 'Return';
      case 0x1B: return 'Escape';
      case 0x20: return 'space';
      case 0x21: return 'Page_Up';
      case 0x22: return 'Page_Down';
      case 0x23: return 'End';
      case 0x24: return 'Home';
      case 0x25: return 'Left';
      case 0x26: return 'Up';
      case 0x27: return 'Right';
      case 0x28: return 'Down';
      case 0x41: return 'a';
      case 0x42: return 'b';
      case 0x43: return 'c';
      case 0x45: return 'e';
      case 0x49: return 'i';
      case 0x4C: return 'l';
      case 0x50: return 'p';
      case 0x57: return 'w';
      case 0x74: return 'F5';
      case 0x11: return 'ctrl';
      case 0x12: return 'alt';
      case 0x10: return 'shift';
      case 0x5B: return 'super'; // Windows key
      case 0xB3: return 'XF86AudioPlay';
      case 0xB0: return 'XF86AudioNext';
      case 0xB1: return 'XF86AudioPrev';
      case 0xB2: return 'XF86AudioStop';
      case 0xAF: return 'XF86AudioRaiseVolume';
      case 0xAE: return 'XF86AudioLowerVolume';
      case 0xAD: return 'XF86AudioMute';
      default: return null;
    }
  }
}
