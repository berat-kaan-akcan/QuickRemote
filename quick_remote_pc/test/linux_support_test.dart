import 'package:flutter_test/flutter_test.dart';
import 'package:quick_remote_pc/services/input/command_router.dart';
import 'package:quick_remote_pc/services/input/linux/evdev_keys.dart';
import 'package:quick_remote_pc/services/input/linux/impress_bridge.dart';
import 'package:quick_remote_pc/services/input/linux/mpris_controller.dart';
import 'package:quick_remote_pc/services/input/linux/pactl_volume.dart';
import 'package:quick_remote_pc/services/linux/linux_setup.dart';
import 'package:quick_remote_pc/services/server/network/linux_network.dart';

void main() {
  group('CommandRouter.parseIntArg', () {
    test('parses values inside the range', () {
      expect(CommandRouter.parseIntArg('VOLUME_SET:42', min: 0, max: 100), 42);
      expect(CommandRouter.parseIntArg('SET_PEN_COLOR:16777215', min: 0, max: 0xFFFFFF), 0xFFFFFF);
    });

    test('rejects out-of-range, missing and non-numeric values', () {
      expect(CommandRouter.parseIntArg('VOLUME_SET:101', min: 0, max: 100), isNull);
      expect(CommandRouter.parseIntArg('START_AT:0', min: 1), isNull);
      expect(CommandRouter.parseIntArg('START_AT:abc', min: 1), isNull);
      expect(CommandRouter.parseIntArg('START_AT', min: 1), isNull);
    });
  });

  group('Evdev.fromVk', () {
    test('maps letters, digits and function keys', () {
      expect(Evdev.fromVk(0x41), 30); // A
      expect(Evdev.fromVk(0x42), Evdev.keyB);
      expect(Evdev.fromVk(0x57), Evdev.keyW);
      expect(Evdev.fromVk(0x30), 11); // 0
      expect(Evdev.fromVk(0x31), 2); // 1
      expect(Evdev.fromVk(0x74), Evdev.keyF5);
    });

    test('maps navigation and media keys', () {
      expect(Evdev.fromVk(0x22), Evdev.keyPageDown);
      expect(Evdev.fromVk(0x21), Evdev.keyPageUp);
      expect(Evdev.fromVk(0xB3), Evdev.keyPlayPause);
      expect(Evdev.fromVk(0x5B), Evdev.keyLeftMeta);
      expect(Evdev.fromVk(0xFF), isNull);
    });

    test('every mappable key is registered on the device', () {
      final registered = Evdev.allKeys.toSet();
      for (var vk = 0; vk < 0x100; vk++) {
        final key = Evdev.fromVk(vk);
        if (key != null) expect(registered, contains(key), reason: 'VK 0x${vk.toRadixString(16)}');
      }
    });
  });

  group('PactlVolume parsing', () {
    test('reads the first channel percentage', () {
      const out = 'Volume: front-left: 32768 /  50% / -18.06 dB,   front-right: 32768 /  50% / -18.06 dB\n'
          '        balance 0.00\n';
      expect(PactlVolume.parseVolume(out), 50);
      expect(PactlVolume.parseVolume('garbage'), isNull);
    });

    test('reads the mute flag', () {
      expect(PactlVolume.parseMute('Mute: yes\n'), isTrue);
      expect(PactlVolume.parseMute('Mute: no\n'), isFalse);
      expect(PactlVolume.parseMute(''), isNull);
    });
  });

  test('MprisController.mapMetadata produces the SMTC_STATE shape', () {
    final state = MprisController.mapMetadata(
      {
        'xesam:title': 'Song',
        'xesam:artist': ['A', 'B'],
        'mpris:length': 180000000,
      },
      status: 'Playing',
      positionUs: 42000000,
    );
    expect(state, {
      'hasMedia': true,
      'title': 'Song',
      'artist': 'A, B',
      'positionMs': 42000,
      'durationMs': 180000,
      'isPlaying': true,
    });
  });

  group('MprisController.looksLikeImage', () {
    test('accepts common image formats', () {
      expect(MprisController.looksLikeImage([0xFF, 0xD8, 0xFF, 0xE0, 0, 0]), isTrue); // JPEG
      expect(MprisController.looksLikeImage([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0]), isTrue); // PNG
      expect(MprisController.looksLikeImage('GIF89a'.codeUnits), isTrue);
      expect(MprisController.looksLikeImage('RIFF\x00\x00\x00\x00WEBPVP8 '.codeUnits), isTrue);
    });

    test('rejects anything else', () {
      expect(MprisController.looksLikeImage('-----BEGIN OPENSSH PRIVATE KEY-----'.codeUnits), isFalse);
      expect(MprisController.looksLikeImage('RIFF\x00\x00\x00\x00WAVEfmt '.codeUnits), isFalse);
      expect(MprisController.looksLikeImage([]), isFalse);
    });
  });

  group('LinuxSetup.registryStatusOf', () {
    String item(String url) => '<item oor:path="/org.openoffice.Setup/Office"><prop '
        'oor:name="ooSetupConnectionURL" oor:op="fuse"><value>$url</value></prop></item>';
    String profile(String url) => '<oor:items>\n${item(url)}\n</oor:items>';

    test('recognizes the user-only pipe listener', () {
      expect(LinuxSetup.registryStatusOf(profile(ImpressBridge.acceptString)), ImpressStatus.readyWhenOpened);
    });

    test('flags the legacy localhost TCP listener', () {
      expect(LinuxSetup.registryStatusOf(profile(ImpressBridge.legacyAcceptString)), ImpressStatus.legacyListener);
    });

    test('reports a profile without the entry as not configured', () {
      expect(LinuxSetup.registryStatusOf('<oor:items>\n</oor:items>'), ImpressStatus.notConfigured);
    });

    test('enabling migrates a legacy profile to the pipe', () {
      final migrated = LinuxSetup.applyRegistryItem(
        profile(ImpressBridge.legacyAcceptString),
        item(ImpressBridge.acceptString),
      );
      expect(LinuxSetup.registryStatusOf(migrated), ImpressStatus.readyWhenOpened);
      expect(migrated, isNot(contains('socket,')));
    });
  });

  test('LinuxNetwork.parseRoute extracts device and source address', () {
    final route = LinuxNetwork.parseRoute('1.1.1.1 via 192.168.1.1 dev wlan0 src 192.168.1.177 uid 1000\n    cache\n');
    expect(route.dev, 'wlan0');
    expect(route.src, '192.168.1.177');
    expect(LinuxNetwork.parseRoute('').src, isNull);
  });

  group('LinuxSetup.applyRegistryItem', () {
    const item = '<item oor:path="/org.openoffice.Setup/Office"><prop oor:name="ooSetupConnectionURL" '
        'oor:op="fuse"><value>NEW</value></prop></item>';

    test('creates a profile file when none exists', () {
      final xcu = LinuxSetup.applyRegistryItem(null, item);
      expect(xcu, contains('<oor:items'));
      expect(xcu, contains(item));
    });

    test('appends to an existing profile', () {
      const existing = '<?xml version="1.0"?>\n<oor:items>\n<item oor:path="/x"><prop oor:name="y"/></item>\n</oor:items>\n';
      final xcu = LinuxSetup.applyRegistryItem(existing, item);
      expect(xcu, contains('<item oor:path="/x">'));
      expect(xcu.indexOf(item), lessThan(xcu.indexOf('</oor:items>')));
    });

    test('replaces a previous connection URL instead of duplicating it', () {
      const existing = '<oor:items>\n<item oor:path="/org.openoffice.Setup/Office"><prop '
          'oor:name="ooSetupConnectionURL" oor:op="fuse"><value>OLD</value></prop></item>\n</oor:items>';
      final xcu = LinuxSetup.applyRegistryItem(existing, item);
      expect(xcu, isNot(contains('OLD')));
      expect('ooSetupConnectionURL'.allMatches(xcu).length, 1);
    });
  });
}
