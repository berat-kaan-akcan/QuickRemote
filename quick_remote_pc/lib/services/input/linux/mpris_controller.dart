import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:dbus/dbus.dart';
import 'package:flutter/foundation.dart';

/// "Now playing" info and media transport through MPRIS (the Linux
/// counterpart of Windows SMTC). Spotify, Firefox, Chromium, VLC, mpv… all
/// publish an `org.mpris.MediaPlayer2.*` name on the session bus.
class MprisController {
  static const _prefix = 'org.mpris.MediaPlayer2.';
  static const _playerIface = 'org.mpris.MediaPlayer2.Player';
  static final _path = DBusObjectPath('/org/mpris/MediaPlayer2');
  static const _maxThumbnailBytes = 1024 * 1024;

  DBusClient? _client;
  String? _thumbUrl;
  String _thumbBase64 = '';

  DBusClient get _bus => _client ??= DBusClient.session();

  Future<void> _resetBus() async {
    final old = _client;
    _client = null;
    try {
      await old?.close();
    } catch (_) {}
  }

  /// Picks the playing player, else a paused one, else the first found.
  Future<DBusRemoteObject?> _activePlayer() async {
    final names = (await _bus.listNames())
        .where((n) => n.startsWith(_prefix) && !n.startsWith('${_prefix}playerctld'))
        .toList();
    if (names.isEmpty) return null;

    DBusRemoteObject? paused;
    for (final name in names) {
      final obj = DBusRemoteObject(_bus, name: name, path: _path);
      try {
        final status = (await obj.getProperty(_playerIface, 'PlaybackStatus')).asString();
        if (status == 'Playing') return obj;
        if (status == 'Paused') paused ??= obj;
      } catch (_) {}
    }
    return paused ?? DBusRemoteObject(_bus, name: names.first, path: _path);
  }

  Future<Map<String, dynamic>> getState() async {
    try {
      final player = await _activePlayer();
      if (player == null) return {'hasMedia': false};

      final status = (await player.getProperty(_playerIface, 'PlaybackStatus')).asString();
      final metadata = (await player.getProperty(_playerIface, 'Metadata')).toNative() as Map;
      int positionUs = 0;
      try {
        positionUs = (await player.getProperty(_playerIface, 'Position')).toNative() as int;
      } catch (_) {
        // Some players don't implement Position.
      }

      final state = mapMetadata(metadata, status: status, positionUs: positionUs);
      state['thumbnail'] = await _thumbnail(metadata['mpris:artUrl'] as String?);
      return state;
    } catch (e) {
      debugPrint('MPRIS state error: $e');
      await _resetBus();
      return {'hasMedia': false};
    }
  }

  /// Converts MPRIS metadata to the SMTC_STATE shape used by the Windows side.
  @visibleForTesting
  static Map<String, dynamic> mapMetadata(Map metadata, {required String status, required int positionUs}) {
    final artist = metadata['xesam:artist'];
    final lengthUs = metadata['mpris:length'];
    return {
      'hasMedia': true,
      'title': (metadata['xesam:title'] as String?) ?? '',
      'artist': artist is Iterable ? artist.join(', ') : (artist as String? ?? ''),
      'positionMs': positionUs ~/ 1000,
      'durationMs': lengthUs is int ? lengthUs ~/ 1000 : 0,
      'isPlaying': status == 'Playing',
    };
  }

  Future<String> _thumbnail(String? url) async {
    if (url == null || url.isEmpty) return '';
    if (url == _thumbUrl) return _thumbBase64;

    List<int>? bytes;
    try {
      final uri = Uri.parse(url);
      if (uri.scheme == 'file') {
        final file = File(uri.toFilePath());
        if (await file.length() <= _maxThumbnailBytes) bytes = await file.readAsBytes();
      } else if (uri.scheme == 'http' || uri.scheme == 'https') {
        final client = HttpClient()..connectionTimeout = const Duration(seconds: 3);
        try {
          final response = await (await client.getUrl(uri)).close().timeout(const Duration(seconds: 3));
          final builder = BytesBuilder(copy: false);
          await for (final chunk in response) {
            builder.add(chunk);
            if (builder.length > _maxThumbnailBytes) break;
          }
          if (builder.length <= _maxThumbnailBytes) bytes = builder.takeBytes();
        } finally {
          client.close(force: true);
        }
      } else if (uri.scheme == 'data') {
        bytes = uri.data?.contentAsBytes();
      }
    } catch (e) {
      debugPrint('MPRIS thumbnail error: $e');
    }

    _thumbUrl = url;
    _thumbBase64 = bytes == null ? '' : base64Encode(bytes);
    return _thumbBase64;
  }

  /// Calls a Player method (PlayPause/Next/Previous/Stop).
  /// Returns false when no MPRIS player exists so the caller can fall back to media keys.
  Future<bool> call(String method) async {
    try {
      final player = await _activePlayer();
      if (player == null) return false;
      await player.callMethod(_playerIface, method, [], replySignature: DBusSignature(''));
      return true;
    } catch (e) {
      debugPrint('MPRIS $method error: $e');
      await _resetBus();
      return false;
    }
  }
}
