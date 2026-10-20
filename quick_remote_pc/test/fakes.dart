import 'package:quick_remote_pc/services/input/input_service.dart';
import 'package:quick_remote_pc/services/mouse_controller.dart';
import 'package:quick_remote_pc/services/overlay/laser_overlay.dart';

/// Records every InputService call by name (with arguments for the few that
/// take any). Methods without an explicit override land in [noSuchMethod].
class FakeInputService implements InputService {
  final List<String> calls = [];
  Map<String, dynamic>? slideState = {'error': 'POWERPOINT_NOT_RUNNING'};
  Map<String, dynamic>? smtcState;

  @override
  CommandErrorHandler? onCommandError;
  @override
  String get presenter => 'fake';
  @override
  List<String> get presenters => const ['fake', 'other'];
  @override
  bool get handlesLaserPointer => false;
  @override
  void laserPointerMoved(double relX, double relY) =>
      calls.add('laserPointerMoved');
  @override
  bool handlesDrawPointer = false;
  @override
  void drawPointerMoved(double relX, double relY) =>
      calls.add('drawPointerMoved');

  /// What [laserArea] answers.
  ScreenArea? area;
  @override
  Future<ScreenArea?> laserArea() async => area;

  @override
  Future<Map<String, dynamic>?> getSlideState() async => slideState;
  @override
  Future<Map<String, dynamic>?> getSmtcState() async => smtcState;
  @override
  Future<VolumeState?> getVolumeState() async => null;

  /// Answers [exportSlide]; null exports nothing.
  SlideImage? Function(int index, int width)? exporter;

  /// Every exportSlide call as (index, width).
  final List<(int, int)> exports = [];

  /// Completes each export only when this future does, when set.
  Future<void>? exportGate;

  @override
  Future<SlideImage?> exportSlide(int index, int width) async {
    exports.add((index, width));
    if (exportGate != null) await exportGate;
    return exporter?.call(index, width);
  }

  /// What [capabilities] answers.
  PresenterCaps caps = const PresenterCaps();

  /// How many times [capabilities] was read.
  int capsReads = 0;

  @override
  Future<PresenterCaps> capabilities() async {
    capsReads++;
    return caps;
  }

  /// What [captureScreen] answers; null takes no picture.
  ScreenCapture? screen;

  /// How many times [captureScreen] was called.
  int captures = 0;

  @override
  Future<ScreenCapture?> captureScreen() async {
    captures++;
    return screen;
  }

  /// The keepInk of every slide command, as 'slideNext:keep' or
  /// 'slidePrev:clear' (the plain name goes to [calls] as before).
  final List<String> inkChoices = [];

  void _slide(String name, bool keepInk) {
    calls.add(name);
    inkChoices.add('$name:${keepInk ? 'keep' : 'clear'}');
  }

  @override
  void slideNext({bool keepInk = false}) => _slide('slideNext', keepInk);
  @override
  void slidePrev({bool keepInk = false}) => _slide('slidePrev', keepInk);
  @override
  Future<void> slideStart({bool keepInk = false}) async =>
      _slide('slideStart', keepInk);
  @override
  Future<void> slideStartAt(int slideNumber, {bool keepInk = false}) async =>
      _slide('slideStartAt:$slideNumber', keepInk);
  @override
  Future<void> setVolume(int level) async => calls.add('setVolume:$level');
  @override
  Future<void> setPenColor(int bgrColor) async =>
      calls.add('setPenColor:$bgrColor');
  @override
  Future<void> setHighlighterColor(int bgrColor) async =>
      calls.add('setHighlighterColor:$bgrColor');

  @override
  dynamic noSuchMethod(Invocation invocation) {
    calls.add(invocation.memberName.toString().split('"')[1]);
    // Covers both void and Future<void> members.
    return Future<void>.value();
  }
}

class FakeMouse implements MouseController {
  final List<(double, double)> moves = [];

  @override
  void moveDelta(double dx, double dy) => moves.add((dx, dy));
  @override
  int get screenWidth => 1920;
  @override
  int get screenHeight => 1080;
  @override
  double get currentX => 0;
  @override
  double get currentY => 0;

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

/// Records what the overlay was asked to do.
class FakeLaserOverlay implements LaserOverlay {
  final List<String> calls = [];

  @override
  bool supported = true;

  /// What [place] answers: false as if the helper could not start.
  bool starts = true;

  /// The area of the last [place] that moved it.
  ScreenArea? placedOn;

  @override
  Future<bool> place(ScreenArea? area, {bool keep = false}) async {
    calls.add(keep ? 'keep' : 'place');
    if (!keep) placedOn = area;
    return starts;
  }

  @override
  void show() => calls.add('show');

  @override
  void move(double relX, double relY) => calls.add('move');

  @override
  void hide() => calls.add('hide');

  @override
  void inkBegin({
    required bool highlighter,
    required int rgb,
    required double relX,
    required double relY,
  }) => calls.add(
    'inkBegin:${highlighter ? 'highlighter' : 'pen'}:${rgb.toRadixString(16).padLeft(6, '0')}',
  );

  @override
  void inkTo(double relX, double relY) => calls.add('inkTo');

  @override
  void inkEnd() => calls.add('inkEnd');

  @override
  void inkClear() => calls.add('inkClear');

  @override
  bool supportsZoom = false;

  @override
  void zoom(bool on) => calls.add('zoom:${on ? 'on' : 'off'}');

  @override
  void spotlight(bool on) => calls.add('spotlight:${on ? 'on' : 'off'}');

  @override
  void blank(int? rgb) =>
      calls.add('blank:${rgb?.toRadixString(16).padLeft(6, '0') ?? 'off'}');
}
