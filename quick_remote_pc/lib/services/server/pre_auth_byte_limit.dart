import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// Wraps an upgraded socket and destroys it once a client that has not
/// authenticated yet has sent more than [budget] bytes.
///
/// dart:io buffers a whole WebSocket message, every fragment of it, before
/// delivering it, and its `maxPayloadLength` only bounds single frames. Without
/// this, a client that does not know the PIN could fill the server's memory
/// with one endless fragmented message.
class PreAuthByteLimit extends Stream<Uint8List> implements Socket {
  PreAuthByteLimit(this._socket, {required this.budget});

  final Socket _socket;
  final int budget;
  int _received = 0;
  bool _lifted = false;

  static const _webSocketGuid = '258EAFA5-E914-47DA-95CA-C5AB0DC85B11';

  /// Completes the WebSocket handshake for [request] (already checked with
  /// `WebSocketTransformer.isUpgradeRequest`) behind a byte limit.
  ///
  /// The handshake is written here instead of `WebSocketTransformer.upgrade`
  /// so the socket can be wrapped. No Sec-WebSocket-Extensions header goes
  /// out, so permessage-deflate stays off and a tiny compressed frame cannot
  /// expand to gigabytes.
  static Future<(WebSocket, PreAuthByteLimit)> upgrade(
    HttpRequest request, {
    required int budget,
    required int maxFramePayload,
  }) async {
    final key = request.headers.value('sec-websocket-key');
    if (key == null) {
      request.response
        ..statusCode = HttpStatus.badRequest
        ..close();
      throw const WebSocketException('Missing Sec-WebSocket-Key');
    }
    request.response
      ..statusCode = HttpStatus.switchingProtocols
      ..headers.add(HttpHeaders.connectionHeader, 'Upgrade')
      ..headers.add(HttpHeaders.upgradeHeader, 'websocket')
      ..headers.add('Sec-WebSocket-Accept',
          base64.encode(sha1.convert(utf8.encode('$key$_webSocketGuid')).bytes))
      ..headers.contentLength = 0;
    final limited = PreAuthByteLimit(await request.response.detachSocket(), budget: budget);
    final ws = WebSocket.fromUpgradedSocket(
      limited,
      serverSide: true,
      compression: CompressionOptions.compressionOff,
      maxPayloadLength: maxFramePayload,
    );
    return (ws, limited);
  }

  /// Call once the client has authenticated; later traffic is not counted.
  void lift() => _lifted = true;

  @override
  StreamSubscription<Uint8List> listen(
    void Function(Uint8List event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return _socket
        .transform(StreamTransformer<Uint8List, Uint8List>.fromHandlers(
          handleData: (chunk, sink) {
            if (!_lifted) {
              _received += chunk.length;
              if (_received > budget) {
                _socket.destroy();
                sink.close();
                return;
              }
            }
            sink.add(chunk);
          },
        ))
        .listen(onData, onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }

  // Everything below delegates to the wrapped socket.

  @override
  Encoding get encoding => _socket.encoding;
  @override
  set encoding(Encoding value) => _socket.encoding = value;
  @override
  void add(List<int> data) => _socket.add(data);
  @override
  void addError(Object error, [StackTrace? stackTrace]) => _socket.addError(error, stackTrace);
  @override
  Future addStream(Stream<List<int>> stream) => _socket.addStream(stream);
  @override
  Future flush() => _socket.flush();
  @override
  Future close() => _socket.close();
  @override
  Future get done => _socket.done;
  @override
  void write(Object? object) => _socket.write(object);
  @override
  void writeAll(Iterable objects, [String separator = '']) => _socket.writeAll(objects, separator);
  @override
  void writeln([Object? object = '']) => _socket.writeln(object);
  @override
  void writeCharCode(int charCode) => _socket.writeCharCode(charCode);
  @override
  void destroy() => _socket.destroy();
  @override
  bool setOption(SocketOption option, bool enabled) => _socket.setOption(option, enabled);
  @override
  Uint8List getRawOption(RawSocketOption option) => _socket.getRawOption(option);
  @override
  void setRawOption(RawSocketOption option) => _socket.setRawOption(option);
  @override
  int get port => _socket.port;
  @override
  int get remotePort => _socket.remotePort;
  @override
  InternetAddress get address => _socket.address;
  @override
  InternetAddress get remoteAddress => _socket.remoteAddress;
}
