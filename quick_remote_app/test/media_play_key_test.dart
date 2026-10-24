import 'package:flutter_test/flutter_test.dart';
import 'package:quick_remote_shared/quick_remote_shared.dart';
import 'package:quick_remote_app/services/websocket_service.dart';

void main() {
  test('with no player on the PC the play key stays a play key', () {
    final ws = WebSocketService()..handleMessage({'type': 'SMTC_STATE', 'hasMedia': false});
    ws.sendCommand(RemoteCommands.sysMediaPlayPause);
    expect(ws.isPlaying, isFalse);
  });

  test('over a player the key turns at once, before the PC answers', () {
    final ws = WebSocketService()
      ..handleMessage({'type': 'SMTC_STATE', 'hasMedia': true, 'title': 'Song', 'isPlaying': false});
    ws.sendCommand(RemoteCommands.sysMediaPlayPause);
    expect(ws.isPlaying, isTrue);
  });
}
