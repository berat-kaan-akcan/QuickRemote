import 'package:flutter_test/flutter_test.dart';
import 'package:quick_remote_app/services/websocket_service.dart';

void main() {
  test('the auth reply tells whether the laser works outside a show', () {
    final ws = WebSocketService()
      ..handleMessage({'type': 'auth', 'status': 'ok', 'overlay': true});
    expect(ws.toolsAnywhere, isTrue);
  });

  test('a changed setting on the PC arrives as OVERLAY', () {
    final ws = WebSocketService()
      ..handleMessage({'type': 'auth', 'status': 'ok', 'overlay': true});
    var told = 0;
    ws.addListener(() => told++);
    ws.handleMessage({'type': 'OVERLAY', 'overlay': false});
    expect(ws.toolsAnywhere, isFalse);
    expect(told, 1);
  });

  test('the magnifier comes with the auth reply and with OVERLAY', () {
    final ws = WebSocketService()
      ..handleMessage({'type': 'auth', 'status': 'ok', 'overlay': true});
    expect(ws.zoomAvailable, isFalse);
    ws.handleMessage({'type': 'OVERLAY', 'overlay': true, 'zoom': true});
    expect(ws.zoomAvailable, isTrue);
  });
}
