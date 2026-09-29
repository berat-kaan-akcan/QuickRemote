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
      // Any app on the session bus can set artUrl, so the whole fetch is
      // bounded in time and size; a stalled download must not freeze the
      // state poll loop that also drives slide updates.
      bytes = await _loadArt(Uri.parse(url)).timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint('MPRIS thumbnail error: $e');
    }
    // Only images go to the phone, never arbitrary file contents.
    if (bytes != null && !looksLikeImage(bytes)) bytes = null;

    _thumbUrl = url;
    _thumbBase64 = bytes == null ? '' : base64Encode(bytes);
    return _thumbBase64;
  }

  Future<List<int>?> _loadArt(Uri uri) async {
    if (uri.scheme == 'file') {
      final path = uri.toFilePath();
      // Regular files only: devices (/dev/zero) never end, FIFOs never return.
      if (FileSystemEntity.typeSync(path) != FileSystemEntityType.file) return null;
      return _readCapped(File(path).openRead(0, _maxThumbnailBytes + 1));
    }
    if (uri.scheme == 'http' || uri.scheme == 'https') {
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 3);
      try {
        final response = await (await client.getUrl(uri)).close();
        if (response.statusCode != HttpStatus.ok) return null;
        // Idle timeout ends a stalled transfer (and closes the client below).
        return await _readCapped(response.timeout(const Duration(seconds: 3)));
      } finally {
        client.close(force: true);
      }
    }
    if (uri.scheme == 'data') {
      final bytes = uri.data?.contentAsBytes();
      return bytes != null && bytes.length <= _maxThumbnailBytes ? bytes : null;
    }
    return null;
  }

  /// Collects [stream] unless it exceeds [_maxThumbnailBytes].
  static Future<List<int>?> _readCapped(Stream<List<int>> stream) async {
    final builder = BytesBuilder(copy: false);
    await for (final chunk in stream) {
      builder.add(chunk);
      if (builder.length > _maxThumbnailBytes) return null;
    }
    return builder.takeBytes();
  }

  /// JPEG, PNG, GIF, WebP or BMP by magic number.
  @visibleForTesting
  static bool looksLikeImage(List<int> b) {
    bool startsWith(List<int> sig, [int offset = 0]) {
      if (b.length < offset + sig.length) return false;
      for (var i = 0; i < sig.length; i++) {
        if (b[offset + i] != sig[i]) return false;
      }
      return true;
    }

    return startsWith(const [0xFF, 0xD8, 0xFF]) ||
        startsWith(const [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]) ||
        startsWith(const [0x47, 0x49, 0x46, 0x38]) ||
        (startsWith(const [0x52, 0x49, 0x46, 0x46]) && startsWith(const [0x57, 0x45, 0x42, 0x50], 8)) ||
        startsWith(const [0x42, 0x4D]);
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
