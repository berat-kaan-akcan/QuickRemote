import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quick_remote_pc/services/desktop/windows_autostart.dart';
import 'package:quick_remote_pc/services/linux/desktop_entry.dart';
import 'package:quick_remote_pc/services/linux/linux_autostart.dart';

void main() {
  test('the autostart entry starts the app minimized', () {
    final entry = DesktopEntry.render('/opt/Quick Remote/quick_remote_pc', autostart: true);
    expect(entry, contains('Exec="/opt/Quick Remote/quick_remote_pc" --minimized\n'));
    expect(entry, contains('X-GNOME-Autostart-enabled=true\n'));
    expect(entry, contains(DesktopEntry.marker));
    expect(DesktopEntry.render('/opt/qr/app'), isNot(contains('--minimized')));
  });

  test('the Run value quotes the path', () {
    expect(WindowsAutostart.command(r'C:\Program Files\QuickRemote\quick_remote_pc.exe'),
        r'"C:\Program Files\QuickRemote\quick_remote_pc.exe" --minimized');
  });

  group('LinuxAutostart', () {
    late Directory config;
    setUp(() => config = Directory.systemTemp.createTempSync('qr_autostart'));
    tearDown(() => config.deleteSync(recursive: true));

    LinuxAutostart autostart([String exe = '/opt/qr/quick_remote_pc']) =>
        LinuxAutostart(configHome: config.path, executable: exe);
    File entry() => File('${config.path}/autostart/${DesktopEntry.appId}.desktop');

    test('writes and removes its entry', () async {
      expect(await autostart().isEnabled(), isFalse);
      expect(await autostart().setEnabled(true), isTrue);
      expect(entry().readAsStringSync(), DesktopEntry.render('/opt/qr/quick_remote_pc', autostart: true));
      expect(await autostart().isEnabled(), isTrue);
      expect(await autostart().setEnabled(false), isTrue);
      expect(entry().existsSync(), isFalse);
    });

    test('follows a build that moved', () async {
      await autostart().setEnabled(true);
      await autostart('/new/place/quick_remote_pc').refresh();
      expect(entry().readAsStringSync(), contains('Exec=/new/place/quick_remote_pc --minimized'));
    });

    test('never replaces or removes the user\'s own entry', () async {
      entry().createSync(recursive: true);
      entry().writeAsStringSync('[Desktop Entry]\nExec=my-wrapper\n');
      expect(await autostart().setEnabled(true), isTrue);
      expect(await autostart().setEnabled(false), isFalse);
      await autostart().refresh();
      expect(entry().readAsStringSync(), '[Desktop Entry]\nExec=my-wrapper\n');
    });

    test('an entry the desktop turned off counts as off', () {
      expect(LinuxAutostart.isEnabledEntry('[Desktop Entry]\nHidden=true\n'), isFalse);
      expect(LinuxAutostart.isEnabledEntry('[Desktop Entry]\nX-GNOME-Autostart-enabled=false\n'), isFalse);
      expect(LinuxAutostart.isEnabledEntry(DesktopEntry.render('/a', autostart: true)), isTrue);
    });
  });
}
