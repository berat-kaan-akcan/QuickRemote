import 'package:quick_remote_pc/services/input/input_service.dart';
import 'package:quick_remote_pc/services/mouse_controller.dart';

/// Records every InputService call by name (with arguments for the few that
/// take any). Methods without an explicit override land in [noSuchMethod].
class FakeInputService implements InputService {
  final List<String> calls = [];
  Map<String, dynamic>? slideState = {'error': 'POWERPOINT_NOT_RUNNING'};
  Map<String, dynamic>? smtcState;

  @override
  void Function(String detail)? onCommandError;
  @override
  String get presenter => 'fake';
  @override
  List<String> get presenters => const ['fake', 'other'];
  @override
  bool get handlesLaserPointer => false;
  @override
  void laserPointerMoved(double relX, double relY) => calls.add('laserPointerMoved');

  @override
  Future<Map<String, dynamic>?> getSlideState() async => slideState;
  @override
  Future<Map<String, dynamic>?> getSmtcState() async => smtcState;
  @override
  Future<VolumeState?> getVolumeState() async => null;

  @override
  Future<void> slideStartAt(int slideNumber) async => calls.add('slideStartAt:$slideNumber');
  @override
  Future<void> setVolume(int level) async => calls.add('setVolume:$level');
  @override
  Future<void> setPenColor(int bgrColor) async => calls.add('setPenColor:$bgrColor');
  @override
  Future<void> setHighlighterColor(int bgrColor) async => calls.add('setHighlighterColor:$bgrColor');

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
