import 'package:dbus/dbus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quick_remote_pc/services/input/linux/kwin_active_window.dart';

void main() {
  test('the script reports to our bus name on KWin 6 and KWin 5', () {
    final script = KWinActiveWindow.script(':1.42');
    expect(script, contains('var target = ":1.42";'));
    expect(script, contains('"/com/quickremote/ActiveWindow", "com.quickremote.ActiveWindow", "Update"'));
    expect(script, contains('workspace.windowActivated'));
    expect(script, contains('workspace.clientActivated'));
    expect(script, contains('fullScreenChanged'));
  });

  test('a bus name cannot break out of its string', () {
    expect(KWinActiveWindow.script(r'a"b\c'), contains(r'var target = "a\"b\\c";'));
  });

  test('reads an Update call', () {
    final window = KWinActiveWindow.parseUpdate(const [
      DBusString('google-chrome'),
      DBusString('google-chrome'),
      DBusBoolean(true),
      DBusString('{1234}'),
    ])!;
    expect(window.resourceClass, 'google-chrome');
    expect(window.fullscreen, isTrue);
    expect(window.id, '{1234}');
  });

  test('no active window is null', () {
    expect(
      KWinActiveWindow.parseUpdate(const [DBusString(''), DBusString(''), DBusBoolean(false), DBusString('')]),
      isNull,
    );
  });
}
