import 'dart:io';
import 'package:flutter/foundation.dart';
import '../input_service.dart';
import 'evdev_keys.dart';
import 'impress_bridge.dart';
import 'mpris_controller.dart';
import 'pactl_volume.dart';
import 'uinput_device.dart';

/// Linux implementation: LibreOffice Impress over UNO for presentation
/// features, uinput for keyboard/mouse, pactl for volume, MPRIS for media.
///
/// Presentation commands fall back to plain key presses when no Impress
/// slideshow is reachable, so PDF viewers and browser slides still work.
class LinuxInputService implements InputService {
  LinuxInputService() {
    _device.ensureOpen();
  }

  final UinputDevice _device = UinputDevice.instance;
  final ImpressBridge _impress = ImpressBridge.instance;
  final MprisController _mpris = MprisController();
  final PactlVolume _volume = PactlVolume();

  bool _laserViaImpress = false;

  @override
  void Function(String detail)? onCommandError;

  @override
  String get presenter => 'impress';

  /// Runs an Impress command; on failure presses [fallbackKeys] (if any).
  Future<bool> _impressOr(String cmd, {Map<String, Object?> args = const {}, List<int>? fallbackKeys}) async {
    final reply = await _impress.request(cmd, args);
    if (reply['ok'] == true) return true;
    debugPrint('Impress "$cmd" failed: ${reply['error']}');
    if (fallbackKeys != null) _device.combo(fallbackKeys);
    return false;
  }

  /// For features that only exist through Impress: report failures to the phone.
  Future<void> _impressOnly(String cmd, {Map<String, Object?> args = const {}}) async {
    final reply = await _impress.request(cmd, args);
    if (reply['ok'] == true) return;
    final error = '${reply['error']}';
    debugPrint('Impress "$cmd" failed: $error');
    onCommandError?.call(_describeError(error));
  }

  static String _describeError(String error) {
    if (error == 'NOT_RUNNING') return 'Slayt gösterisi aktif değil.';
    if (error == 'NO_MEDIA') return 'Bu slaytta medya yok.';
    if (error == 'NO_CONNECTION') return 'LibreOffice Impress\'e bağlanılamadı.';
    if (error == 'NO_UNO' || error == 'NO_PYTHON') return 'LibreOffice Python (UNO) desteği bulunamadı.';
    if (error == 'UNTRUSTED_PIPE') return 'LibreOffice bağlantı soketi başka bir kullanıcıya ait; bağlanılmadı.';
    if (error == 'MEDIA_RELOADED') return 'Slayt yeniden yüklendi, video baştan başladı. Kontrol için tekrar deneyin.';
    if (error == 'NO_MEDIA_TRIGGER') return 'Bu slayttaki medya kumandadan kontrol edilemiyor.';
    if (error == 'MEDIA_NEEDS_FULLSCREEN') return 'Slayt medyası yalnızca tam ekran slayt gösterisinde kontrol edilebilir.';
    if (error == 'SCREEN_BLANKED') return 'Ekran karartılmışken slayt medyası kontrol edilemez.';
    return 'Impress komutu başarısız: $error';
  }

  // ── States ──
  @override
  Future<Map<String, dynamic>?> getSmtcState() => _mpris.getState();

  @override
  Future<Map<String, dynamic>?> getSlideState() async {
    final reply = await _impress.request('state');
    if (reply['ok'] != true || reply['state'] != 'RUNNING') {
      _laserViaImpress = false;
      return {'error': 'POWERPOINT_NOT_RUNNING'};
    }
    return {
      'current': reply['current'],
      'total': reply['total'],
      'notes': reply['notes'] ?? '',
      'hasMedia': reply['hasMedia'] ?? false,
      'isMediaPlaying': reply['isMediaPlaying'],
      'isBlackScreen': reply['isBlackScreen'] ?? false,
    };
  }

  @override
  Future<VolumeState?> getVolumeState() => _volume.getState();

  // ── Volume ──
  @override
  void volumeUp() => _volume.change(PactlVolume.step);
  @override
  void volumeDown() => _volume.change(-PactlVolume.step);
  @override
  void volumeMute() => _volume.toggleMute();
  @override
  Future<void> setVolume(int level) => _volume.setLevel(level);

  // ── Presentation ──
  @override
  void slideNext() => _impressOr('next', fallbackKeys: [Evdev.keyPageDown]);
  @override
  void slidePrev() => _impressOr('prev', fallbackKeys: [Evdev.keyPageUp]);
  @override
  Future<void> slideStart() => _impressOr('start', fallbackKeys: [Evdev.keyF5]);

  @override
  Future<void> slideStartAt(int slideNumber) async {
    // Without the bridge there is no way to tell whether F5 opened a show, and
    // typing the number + Enter into any other window could send a chat
    // message. So the fallback only starts the show from its first slide.
    await _impressOr('startAt', args: {'slide': slideNumber}, fallbackKeys: [Evdev.keyF5]);
  }

  @override
  Future<void> slideEnd() async {
    _laserViaImpress = false;
    await _impressOr('end', fallbackKeys: [Evdev.keyEsc]);
  }

  @override
  void blackScreen() => _impressOr('blank', args: {'color': 0x000000}, fallbackKeys: [Evdev.keyB]);
  @override
  void whiteScreen() => _impressOr('blank', args: {'color': 0xFFFFFF}, fallbackKeys: [Evdev.keyW]);
  @override
  void eraseAllInk() => _impressOnly('eraseAll');

  @override
  Future<void> setPenColor(int bgrColor) {
    // PowerPoint uses BGR, UNO uses RGB.
    final rgb = ((bgrColor & 0xFF) << 16) | (bgrColor & 0xFF00) | ((bgrColor >> 16) & 0xFF);
    return _impressOnly('penColor', args: {'rgb': rgb});
  }

  @override
  Future<void> pptMediaPlayPause() => _impressOnly('mediaToggle');
  @override
  Future<void> pptMediaRewind() => _impressOnly('mediaRewind');

  // ── Modes ──
  @override
  void toggleLaserCursor() => _laserViaImpress ? laserOff() : modeLaser();

  @override
  void modeArrow() => _setMode('arrow');
  @override
  void modePen() => _setMode('pen');
  @override
  void modeHighlighter() => _setMode('highlighter');
  @override
  void modeEraser() => _setMode('eraser');
  @override
  void laserOff() => _setMode('laserOff');

  @override
  Future<void> modeLaser() async {
    // Route the motion to Impress at once: the bridge handles laserOn before
    // any pointer update sent after it. Waiting for the reply would move the
    // real cursor meanwhile.
    _laserViaImpress = true;
    final reply = await _impress.request('laserOn');
    if (reply['ok'] == true) return;
    _laserViaImpress = false;
    onCommandError?.call(_describeError('${reply['error']}'));
  }

  void _setMode(String cmd) {
    _laserViaImpress = false;
    _impressOnly(cmd);
  }

  @override
  bool get handlesLaserPointer => _laserViaImpress;

  @override
  void laserPointerMoved(double relX, double relY) {
    // No throttling here: the bridge applies only the newest waiting
    // position, and dropping updates would lose the final one.
    _impress.send('pointer', {'x': relX, 'y': relY});
  }

  // ── Mouse & keyboard ──
  @override
  void leftClick() => _device.click(Evdev.btnLeft);
  @override
  void rightClick() => _device.click(Evdev.btnRight);
  @override
  void leftDown() => _device.button(Evdev.btnLeft, down: true);
  @override
  void leftUp() => _device.button(Evdev.btnLeft, down: false);

  @override
  void pressKey(int vkCode) {
    final key = Evdev.fromVk(vkCode);
    if (key != null) _device.tap(key);
  }

  @override
  void pressKeyCombo(List<int> vkCodes) {
    final keys = vkCodes.map(Evdev.fromVk).whereType<int>().toList();
    if (keys.isNotEmpty) _device.combo(keys);
  }

  // ── System ──
  @override
  Future<void> lockPC() async {
    for (final (exe, args) in const [
      ('loginctl', ['lock-session']),
      ('xdg-screensaver', ['lock']),
    ]) {
      try {
        final result = await Process.run(exe, args);
        if (result.exitCode == 0) return;
      } catch (_) {}
    }
    onCommandError?.call('Bilgisayar kilitlenemedi.');
  }

  Future<void> _media(String method, int fallbackKey) async {
    if (!await _mpris.call(method)) _device.tap(fallbackKey);
  }

  @override
  void sysMediaPlayPause() => _media('PlayPause', Evdev.keyPlayPause);
  @override
  void sysMediaNext() => _media('Next', Evdev.keyNextSong);
  @override
  void sysMediaPrev() => _media('Previous', Evdev.keyPreviousSong);
  @override
  void sysMediaStop() => _media('Stop', Evdev.keyStopCd);
}
