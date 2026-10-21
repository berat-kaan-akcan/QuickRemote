import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'discovery_service.dart';
import 'websocket_service.dart';

/// What a way into the app from outside it asks for: the launcher's app
/// shortcuts and the Quick Settings tile (android/.../LaunchLink.kt). They
/// open MainActivity with a quickremote:// link, sent only as explicit
/// intents (no intent filter, so a web page cannot open them).
enum LaunchAction {
  /// quickremote://connect/last: the shortcut "Connect: PC name" and the
  /// tile.
  connectLast,

  /// quickremote://bluetooth: the Bluetooth remote, for the program picked
  /// last (`SettingsProvider.btTarget`).
  bluetooth,

  /// quickremote://scan: the QR scanner.
  scan;

  static LaunchAction? parse(String? link) {
    final uri = link == null ? null : Uri.tryParse(link);
    if (uri == null || uri.scheme != 'quickremote') return null;
    final path = uri.path.replaceAll(RegExp(r'/+$'), '');
    return switch ((uri.host, path)) {
      ('connect', '/last') => connectLast,
      ('bluetooth', '') => bluetooth,
      ('scan', '') => scan,
      _ => null,
    };
  }

  /// Whether the link is let through: never while a remote is in use
  /// (connected or connecting over Wi-Fi, or the computer's Bluetooth
  /// keyboard). Opening the scanner or the Bluetooth screen would close
  /// that remote and leave its connection without a screen; the app just
  /// comes back to the front, on the remote.
  static bool handles({required bool remoteInUse}) => !remoteInUse;
}

/// The Dart end of the `…/launch` channel: hands the links to the home
/// screen, and tells the native side the last PC's name (the dynamic app
/// shortcut, the tile's subtitle) and whether the phone is connected (the
/// tile's state).
class LaunchActions {
  LaunchActions({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(channelName);

  static const channelName = 'com.quickremote.quick_remote_app/launch';
  static final LaunchActions instance = LaunchActions();

  final MethodChannel _channel;
  void Function(LaunchAction action)? _handler;
  WebSocketService? _watched;
  bool? _sentConnected;

  /// Gives the links to [handler] (null stops), starting with the one the
  /// app was opened with. A link that comes while no handler listens stays
  /// on the native side until one does.
  Future<void> listen(void Function(LaunchAction action)? handler) async {
    _handler = handler;
    if (handler == null) {
      _channel.setMethodCallHandler(null);
      return;
    }
    _channel.setMethodCallHandler(_onCall);
    final initial = LaunchAction.parse(await _invoke<String>('initialAction'));
    if (initial != null && _handler == handler) handler(initial);
  }

  Future<Object?> _onCall(MethodCall call) async {
    if (call.method != 'action') throw MissingPluginException(call.method);
    final handler = _handler;
    // An error keeps the link on the native side for initialAction.
    if (handler == null) throw PlatformException(code: 'not_listening');
    final action = LaunchAction.parse(call.arguments as String?);
    if (action != null) handler(action);
    return null;
  }

  /// The PC the shortcut and the tile connect to; null removes the shortcut.
  Future<void> setLastPc(String? name) =>
      _invoke<void>('lastPc', {'name': name});

  /// Follows [ws]'s connection for the tile's state.
  void watchConnection(WebSocketService ws) {
    if (identical(_watched, ws)) return;
    _watched?.removeListener(_onConnection);
    _watched = ws;
    ws.addListener(_onConnection);
    _onConnection();
  }

  void _onConnection() {
    final connected = _watched?.isConnected ?? false;
    if (_sentConnected == connected) return;
    _sentConnected = connected;
    _invoke<void>('connected', {'connected': connected});
  }

  Future<T?> _invoke<T>(String method, [Object? arguments]) async {
    try {
      return await _channel.invokeMethod<T>(method, arguments);
    } on MissingPluginException {
      return null; // tests, and platforms without the native side
    } on PlatformException catch (e) {
      debugPrint('launch channel: $e');
      return null;
    }
  }
}

/// A PC from the recent connections (`DeviceHistoryRepository`).
@immutable
class PcAddress {
  const PcAddress({
    required this.host,
    required this.port,
    required this.pin,
    required this.name,
  });

  final String host;
  final int port;
  final String pin;

  /// The PC's mDNS name, or its address when it had none.
  final String name;

  /// The entry of `DeviceHistoryRepository.getRecentDevices`; null when it
  /// has no address or no saved PIN.
  static PcAddress? fromRecent(Map<String, dynamic>? entry) {
    if (entry == null) return null;
    final host = entry['host'];
    final port = entry['port'];
    final pin = entry['pin'];
    if (host is! String || host.isEmpty || port is! int) return null;
    if (pin is! String || pin.isEmpty) return null;
    final name = entry['name'];
    return PcAddress(
      host: host,
      port: port,
      pin: pin,
      name: name is String && name.isNotEmpty ? name : host,
    );
  }

  PcAddress movedTo(DiscoveredDevice device) =>
      PcAddress(host: device.ip, port: device.port, pin: pin, name: name);

  @override
  bool operator ==(Object other) =>
      other is PcAddress &&
      other.host == host &&
      other.port == port &&
      other.pin == pin &&
      other.name == name;

  @override
  int get hashCode => Object.hash(host, port, pin, name);

  @override
  String toString() => 'PcAddress($name, $host:$port)';
}

/// How "connect to the last PC" ended.
sealed class LastPcOutcome {
  const LastPcOutcome();
}

/// Connected to [pc]. [movedFrom]: the address it had in the history, when
/// mDNS found it at a new one.
class LastPcConnected extends LastPcOutcome {
  const LastPcConnected(this.pc, {this.movedFrom});
  final PcAddress pc;
  final PcAddress? movedFrom;
}

/// No recent PC with a saved PIN.
class LastPcMissing extends LastPcOutcome {
  const LastPcMissing();
}

/// The PC answered neither at its address nor under its name over mDNS.
class LastPcNotFound extends LastPcOutcome {
  const LastPcNotFound(this.pc);
  final PcAddress pc;
}

/// The PC was reached but the attempt failed ([error]: wrong PIN, a
/// certificate that differs from the pinned one, …; [ConnectionError.none]
/// when the user cancelled the security code dialog).
class LastPcFailed extends LastPcOutcome {
  const LastPcFailed(this.pc, this.error);
  final PcAddress pc;
  final ConnectionError error;
}

/// One connection attempt: null when connected, else why not
/// ([ConnectionError.none]: cancelled by the user). [fingerprint] pins the
/// certificate for the attempt, as a QR code's does.
typedef PcConnector =
    Future<ConnectionError?> Function(PcAddress pc, String? fingerprint);

/// quickremote://connect/last: connects to the most recent PC with its
/// saved PIN. Its certificate stays pinned (`cert_fingerprint_<host>`), so
/// the security is that of a recent connection. When the PC is not at its
/// saved address (DHCP gave it a new one), the PC with the same mDNS name is
/// tried, with the certificate pinned for the old address: a different PC
/// under that name fails ([ConnectionError.certRejected]) and never sees the
/// PIN.
class LastPcConnect {
  /// Errors that mean nothing answered at the address.
  static const unreachable = {
    ConnectionError.timeout,
    ConnectionError.serverNotFound,
    ConnectionError.closed,
    ConnectionError.unknown,
  };

  /// [found] is the PCs mDNS sees now (`DiscoveryService.devices`);
  /// [fingerprintOf] reads the certificate pinned for a host. When the saved
  /// address does not answer, mDNS is watched for [searchFor].
  static Future<LastPcOutcome> run({
    required List<Map<String, dynamic>> recent,
    required List<DiscoveredDevice> Function() found,
    required Future<String?> Function(String host) fingerprintOf,
    required PcConnector connect,
    Duration searchFor = const Duration(seconds: 6),
    Duration pollEvery = const Duration(milliseconds: 250),
  }) async {
    final last = PcAddress.fromRecent(recent.firstOrNull);
    if (last == null) return const LastPcMissing();

    Future<LastPcOutcome> tryMoved(DiscoveredDevice device) async {
      final moved = last.movedTo(device);
      final error = await connect(moved, await fingerprintOf(last.host));
      if (error == null) return LastPcConnected(moved, movedFrom: last);
      if (unreachable.contains(error)) return LastPcNotFound(last);
      return LastPcFailed(moved, error);
    }

    // mDNS already sees it elsewhere: no wait for the old address.
    final seen = found();
    final atSaved = seen.any((d) => d.ip == last.host && d.port == last.port);
    final elsewhere = atSaved ? null : movedDevice(last, seen);
    if (elsewhere != null) return tryMoved(elsewhere);

    final error = await connect(last, null);
    if (error == null) return LastPcConnected(last);
    if (!unreachable.contains(error)) return LastPcFailed(last, error);

    final watch = Stopwatch()..start();
    while (watch.elapsed < searchFor) {
      final device = movedDevice(last, found());
      if (device != null) return tryMoved(device);
      await Future<void>.delayed(pollEvery);
    }
    return LastPcNotFound(last);
  }

  /// The PC mDNS sees under [last]'s name at another address. None when
  /// [last] was saved without a name (its address stands in for it).
  static DiscoveredDevice? movedDevice(
    PcAddress last,
    List<DiscoveredDevice> found,
  ) {
    if (last.name == last.host) return null;
    final name = last.name.toLowerCase();
    return found
        .where((d) => d.name.toLowerCase() == name)
        .where((d) => d.ip != last.host || d.port != last.port)
        .firstOrNull;
  }

  /// The certificate fingerprint pinned for [host], where
  /// `WebSocketClient.connect` keeps it.
  static Future<String?> pinnedFingerprint(String host) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('cert_fingerprint_$host');
  }
}
