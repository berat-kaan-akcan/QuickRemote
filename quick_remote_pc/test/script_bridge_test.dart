import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quick_remote_pc/services/input/linux/script_bridge.dart';

class _PythonBridge extends ScriptBridge {
  _PythonBridge(String script) : super('TestBridge', 'test.py') {
    scriptPathOverride = script;
  }

  @override
  Future<String?> interpreter() async => Platform.isWindows ? 'python' : 'python3';
}

void main() {
  late Directory dir;

  setUp(() => dir = Directory.systemTemp.createTempSync('script_bridge_test'));
  tearDown(() => dir.deleteSync(recursive: true));

  String script(String body) {
    final file = File('${dir.path}/test.py')..writeAsStringSync(body);
    return file.path;
  }

  test('answers by id', () async {
    final bridge = _PythonBridge(script('''
import json, sys
for line in sys.stdin:
    r = json.loads(line)
    print(json.dumps({"id": r["id"], "ok": True, "cmd": r["cmd"]}))
'''));
    final reply = await bridge.request('ping');
    expect(reply, containsPair('cmd', 'ping'));
    bridge.restart();
  });

  test('a process that has exited breaks no pipe loudly', () async {
    final errors = <Object>[];
    await runZonedGuarded(() async {
      final bridge = _PythonBridge(script('import sys\nsys.exit(0)\n'));
      for (var i = 0; i < 5; i++) {
        final reply = await bridge.request('ping', const {}, const Duration(milliseconds: 300));
        expect(reply['ok'], isFalse);
        await Future<void>.delayed(const Duration(milliseconds: 50));
        bridge.send('pointer', {'x': 0.5, 'y': 0.5});
      }
      await Future<void>.delayed(const Duration(milliseconds: 300));
      bridge.restart();
    }, (e, _) => errors.add(e));
    expect(errors, isEmpty);
  });

  test('a reply that is not an object is ignored', () async {
    final bridge = _PythonBridge(script('''
import json, sys
for line in sys.stdin:
    r = json.loads(line)
    print("[1]")
    print("null")
    print(json.dumps({"id": r["id"], "ok": True}))
'''));
    expect((await bridge.request('ping'))['ok'], isTrue);
    bridge.restart();
  });
}
