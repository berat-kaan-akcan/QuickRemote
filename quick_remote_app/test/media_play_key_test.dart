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

  // The PC sends the cover and the volume only when they change. The empty
  // SLIDE_STATE it sends without a show used to drop them, and the cover did
  // not come back until the next track (2026-10-28).
  test('a show that ends keeps the cover, the track and the volume', () {
    final ws = WebSocketService()
      ..handleMessage({'type': 'STATUS', 'state': 'VOLUME_CHANGED', 'volume': 54, 'muted': false})
      ..handleMessage({'type': 'SMTC_STATE', 'hasMedia': true, 'title': 'Song', 'artist': 'Singer', 'thumbnail': 'aVZCT1I='})
      ..handleMessage({'type': 'SLIDE_STATE', 'current': 3, 'total': 9})
      ..handleMessage({'type': 'SLIDE_STATE', 'data': null, 'front': 'other'})
      ..handleMessage({'type': 'SMTC_STATE', 'hasMedia': true, 'title': 'Song', 'artist': 'Singer', 'positionMs': 2000});
    expect(ws.mediaThumbnailBase64, 'aVZCT1I=');
    expect(ws.mediaTitle, 'Song');
    expect(ws.systemVolume, 54);
    expect(ws.currentSlide, 0);
  });

  test('a lost connection drops what plays on the PC', () async {
    final ws = WebSocketService()
      ..handleMessage({'type': 'SMTC_STATE', 'hasMedia': true, 'title': 'Song', 'thumbnail': 'aVZCT1I='});
    await ws.disconnect();
    expect(ws.mediaThumbnailBase64, isNull);
    expect(ws.hasMedia, isFalse);
  });
}
