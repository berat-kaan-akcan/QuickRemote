import 'package:flutter_test/flutter_test.dart';
import 'package:quick_remote_pc/services/linux/desktop_entry.dart';

void main() {
  test('plain paths are not quoted', () {
    expect(DesktopEntry.quoteExec('/home/berat/Masaüstü/app/quick_remote_pc'),
        '/home/berat/Masaüstü/app/quick_remote_pc');
  });

  test('paths with reserved characters are quoted and escaped', () {
    expect(DesktopEntry.quoteExec('/opt/Quick Remote/app'), '"/opt/Quick Remote/app"');
    expect(DesktopEntry.quoteExec(r'/opt/a$b/app'), r'"/opt/a\\$b/app"');
  });

  test('the entry matches the window app id', () {
    final entry = DesktopEntry.render('/opt/qr/quick_remote_pc');
    expect(entry, contains('Exec=/opt/qr/quick_remote_pc\n'));
    expect(entry, contains('Icon=${DesktopEntry.appId}\n'));
    expect(entry, contains('StartupWMClass=${DesktopEntry.appId}\n'));
  });
}
