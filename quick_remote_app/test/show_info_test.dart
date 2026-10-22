import 'package:flutter_test/flutter_test.dart';
import 'package:quick_remote_app/providers/settings_provider.dart';
import 'package:quick_remote_app/screens/remote/utils/show_info.dart';
import 'package:quick_remote_app/services/websocket_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The state the PC reported, without a connection.
class _Ws extends WebSocketService {
  _Ws({this.running = true, this.current = 4, this.total = 12, this.presenterId = 'powerpoint', this.platform = 'windows'});

  final bool running;
  final int current;
  final int total;
  final String presenterId;
  final String? platform;

  @override
  bool get isPptRunning => running;
  @override
  int get currentSlide => current;
  @override
  int get totalSlides => total;
  @override
  String get presenter => presenterId;
  @override
  String? get pcPlatform => platform;
  String? front;
  @override
  String? get frontPresenter => front;
  @override
  String get serverAddress => '192.168.1.24:8443';
  @override
  List<String> get presenters => platform == 'linux' ? const ['impress', 'wps'] : const ['powerpoint', 'wps'];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('without a show the remote names the program in front', () async {
    SharedPreferences.setMockInitialValues({});
    final settings = SettingsProvider();
    final ws = _Ws(running: false, platform: 'linux')..front = 'wps';
    expect(remoteProgram(ws, settings), 'wps');
    ws.front = null;
    expect(remoteProgram(ws, settings), 'impress');
  });

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('a readable PowerPoint show has everything', () {
    final show = ShowInfo.of(_Ws());
    expect(show.running, isTrue);
    expect(show.unreadable, isFalse);
    expect(show.windowsWps, isFalse);
    expect(show.colorsAvailable, isTrue);
    expect(show.canJump, isTrue);
  });

  test('WPS on Windows has the arrow, no rewind, no play state', () {
    final show = ShowInfo.of(_Ws(presenterId: 'wps'));
    expect(show.windowsWps, isTrue);
    expect(show.userWps, isFalse);
  });

  test('a WPS on Linux that QuickRemote did not open: no number, colors or jumps', () {
    final show = ShowInfo.of(_Ws(presenterId: 'wps', platform: 'linux', current: 0, total: 0));
    expect(show.unreadable, isTrue);
    expect(show.userWps, isTrue);
    expect(show.colorsAvailable, isFalse);
    expect(show.canJump, isFalse);
  });

  test('without a show nothing is running, and nothing is WPS', () {
    final show = ShowInfo.of(_Ws(running: false, presenterId: 'wps', current: 0, total: 0));
    expect(show.running, isFalse);
    expect(show.unreadable, isFalse);
    expect(show.windowsWps, isFalse);
  });

  test('the remote names the running program, else the marked one, else the first', () async {
    final settings = SettingsProvider();
    await Future.delayed(Duration.zero);
    expect(remoteProgram(_Ws(running: false), settings), 'powerpoint');

    await settings.setPresenterFor('192.168.1.24:8443', 'wps');
    expect(remoteProgram(_Ws(running: false), settings), 'wps');
    // A running show wins over the mark.
    expect(remoteProgram(_Ws(presenterId: 'powerpoint'), settings), 'powerpoint');
    // A mark for a program this PC does not control is ignored.
    await settings.setPresenterFor('192.168.1.24:8443', 'impress');
    expect(remoteProgram(_Ws(running: false), settings), 'powerpoint');

    final reloaded = SettingsProvider();
    await Future.delayed(Duration.zero);
    expect(reloaded.presenterFor('192.168.1.24:8443'), 'impress');
  });
}
