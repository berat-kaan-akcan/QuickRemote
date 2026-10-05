import 'dart:async';

import 'package:dbus/dbus.dart';
import 'package:flutter/foundation.dart';
import 'package:quick_remote_shared/quick_remote_shared.dart';

/// Offers the [BtHidRepair] RFCOMM service through BlueZ and, when a phone
/// connects to it, makes BlueZ read the phone's SDP records again.
///
/// BlueZ reads a device's records when pairing, and later only for a
/// connection the computer starts, once per connection. A phone paired while
/// QuickRemote's HID record was not registered is refused as a keyboard
/// ("Could not parse HID SDP record", "unknown device"); the phone's
/// Bluetooth remote then connects here. See [refreshServices] for how the
/// records are read again.
class BluezHidRepair {
  BluezHidRepair._();

  static final BluezHidRepair instance = BluezHidRepair._();

  static const _bluez = 'org.bluez';
  static final _profilePath = DBusObjectPath('/com/quickremote/hid_repair');

  DBusClient? _client;
  StreamSubscription<DBusNameOwnerChangedEvent>? _bluezRestarts;
  final _throttle = RepairThrottle();

  /// Registers the service; again whenever bluetoothd (re)starts.
  Future<void> start() async {
    if (_client != null) return;
    final client = DBusClient.system();
    _client = client;
    try {
      await client.registerObject(_RepairProfile(_profilePath, _onConnection));
      _bluezRestarts = client.nameOwnerChanged
          .where((e) => e.name == _bluez && e.newOwner != null)
          .listen((_) => _register(client));
      await _register(client);
    } catch (e) {
      debugPrint('BluezHidRepair: not started: $e');
      await stop();
    }
  }

  Future<void> stop() async {
    await _bluezRestarts?.cancel();
    _bluezRestarts = null;
    final client = _client;
    _client = null;
    // Closing the connection also unregisters the profile.
    await client?.close();
  }

  Future<void> _register(DBusClient client) async {
    final manager = DBusRemoteObject(client, name: _bluez, path: DBusObjectPath('/org/bluez'));
    try {
      await manager.callMethod(
        'org.bluez.ProfileManager1',
        'RegisterProfile',
        [
          _profilePath,
          const DBusString(BtHidRepair.serviceUuid),
          DBusDict.stringVariant({
            'Name': const DBusString('QuickRemote'),
            'Role': const DBusString('server'),
            'Channel': const DBusUint16(0), // any free RFCOMM channel
            'RequireAuthentication': const DBusBoolean(true), // bonded phones only
            'RequireAuthorization': const DBusBoolean(false), // no dialog
            'AutoConnect': const DBusBoolean(false),
          }),
        ],
        replySignature: DBusSignature(''),
      );
      debugPrint('BluezHidRepair: registered');
    } on DBusMethodResponseException catch (e) {
      // No adapter or bluetoothd: tried again when it starts.
      debugPrint('BluezHidRepair: RegisterProfile failed: ${e.errorName}');
    }
  }

  Future<void> _onConnection(DBusObjectPath device) async {
    final client = _client;
    if (client == null || !_throttle.tryAcquire(device.value, DateTime.now())) return;
    debugPrint('BluezHidRepair: reading the records of $device again');
    try {
      await refreshServices(_DbusBluezDevice(client, device));
    } catch (e) {
      debugPrint('BluezHidRepair: refresh failed: $e');
    }
  }
}

/// The org.bluez.Device1 calls [refreshServices] needs.
abstract class BluezDevice {
  Future<bool> get servicesResolved;
  Future<bool> get connected;
  Future<void> disconnect();
  Future<void> connect();
  Future<void> connectProfile(String uuid);
}

/// Makes BlueZ read [device]'s SDP records again.
///
/// ConnectProfile with a UUID none of the phone's services has is a plain SDP
/// search, unless the records were already read on this connection
/// (ServicesResolved): then BlueZ answers NotAvailable without searching, so
/// the phone is disconnected first and connected again afterwards, which also
/// restores its audio and connects the keyboard.
Future<void> refreshServices(
  BluezDevice device, {
  Duration pollInterval = const Duration(milliseconds: 200),
  Duration disconnectTimeout = const Duration(seconds: 5),
  Duration busyRetryDelay = const Duration(seconds: 1),
}) async {
  final reconnect = await device.servicesResolved;
  if (reconnect) {
    await device.disconnect();
    final deadline = DateTime.now().add(disconnectTimeout);
    while (await device.connected && DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(pollInterval);
    }
  }
  // The phone may be reconnecting its audio meanwhile (InProgress).
  for (var attempt = 0; attempt < 3; attempt++) {
    try {
      await device.connectProfile(BtHidRepair.serviceUuid);
      break;
    } on DBusMethodResponseException catch (e) {
      if (e.errorName != 'org.bluez.Error.InProgress') break; // NotAvailable: searched
      await Future<void>.delayed(busyRetryDelay);
    }
  }
  if (reconnect) {
    try {
      await device.connect();
    } on DBusMethodResponseException catch (e) {
      debugPrint('BluezHidRepair: reconnect failed: ${e.errorName}');
    }
  }
}

/// At most one refresh per device every [interval]: each one may drop the
/// phone's audio for a moment.
class RepairThrottle {
  RepairThrottle({this.interval = const Duration(seconds: 30)});

  final Duration interval;
  final _last = <String, DateTime>{};

  bool tryAcquire(String key, DateTime now) {
    final last = _last[key];
    if (last != null && now.difference(last) < interval) return false;
    _last[key] = now;
    return true;
  }
}

class _DbusBluezDevice implements BluezDevice {
  _DbusBluezDevice(DBusClient client, DBusObjectPath path)
      : _object = DBusRemoteObject(client, name: 'org.bluez', path: path);

  static const _interface = 'org.bluez.Device1';
  final DBusRemoteObject _object;

  Future<bool> _flag(String name) async =>
      (await _object.getProperty(_interface, name, signature: DBusSignature('b'))).asBoolean();

  Future<void> _call(String method, [List<DBusValue> args = const []]) =>
      _object.callMethod(_interface, method, args, replySignature: DBusSignature(''));

  @override
  Future<bool> get servicesResolved => _flag('ServicesResolved');

  @override
  Future<bool> get connected => _flag('Connected');

  @override
  Future<void> disconnect() => _call('Disconnect');

  @override
  Future<void> connect() => _call('Connect');

  @override
  Future<void> connectProfile(String uuid) => _call('ConnectProfile', [DBusString(uuid)]);
}

/// org.bluez.Profile1, called by bluetoothd.
class _RepairProfile extends DBusObject {
  _RepairProfile(super.path, this._onConnection);

  final Future<void> Function(DBusObjectPath device) _onConnection;

  @override
  Future<DBusMethodResponse> handleMethodCall(DBusMethodCall methodCall) async {
    if (methodCall.interface != 'org.bluez.Profile1') {
      return DBusMethodErrorResponse.unknownInterface();
    }
    switch (methodCall.name) {
      case 'NewConnection':
        if (methodCall.signature != DBusSignature('oha{sv}')) {
          return DBusMethodErrorResponse.invalidArgs();
        }
        // The connection itself is the request; nothing is read from it.
        (methodCall.values[1] as DBusUnixFd).handle.toFile().closeSync();
        unawaited(_onConnection(methodCall.values[0].asObjectPath()));
        return DBusMethodSuccessResponse();
      case 'RequestDisconnection':
      case 'Release':
        return DBusMethodSuccessResponse();
      default:
        return DBusMethodErrorResponse.unknownMethod();
    }
  }
}
