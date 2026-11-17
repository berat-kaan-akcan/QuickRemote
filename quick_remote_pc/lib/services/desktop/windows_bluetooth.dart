import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:win32/win32.dart';

import 'bluetooth_pairing.dart';

/// Windows' paired Bluetooth devices (bluetoothapis). Written on Linux, not
/// yet run on Windows.
class WindowsBluetooth implements BluetoothPairing {
  /// The Bluetooth page of Settings, the one address that is the same on
  /// Windows 10 and 11. The user presses "Add device" there.
  static final settingsPage = Uri.parse('ms-settings:bluetooth');

  @override
  List<PairedDevice> paired() {
    final params = calloc<BLUETOOTH_DEVICE_SEARCH_PARAMS>();
    final info = calloc<BLUETOOTH_DEVICE_INFO>();
    final devices = <PairedDevice>[];
    try {
      params.ref
        ..dwSize = sizeOf<BLUETOOTH_DEVICE_SEARCH_PARAMS>()
        ..fReturnAuthenticated = true
        ..fReturnRemembered = true
        ..fReturnUnknown = false
        ..fReturnConnected = true
        ..fIssueInquiry = false
        ..cTimeoutMultiplier = 0;
      info.ref.dwSize = sizeOf<BLUETOOTH_DEVICE_INFO>();
      final find = BluetoothFindFirstDevice(params, info).value;
      if (find.isNull) return const [];
      try {
        do {
          if (info.ref.fAuthenticated || info.ref.fRemembered) {
            devices.add(
              PairedDevice(
                name: info.ref.szName,
                address: info.ref.Address.Anonymous.ullLong,
                classOfDevice: info.ref.ulClassofDevice,
              ),
            );
          }
          info.ref.dwSize = sizeOf<BLUETOOTH_DEVICE_INFO>();
        } while (BluetoothFindNextDevice(find, info).value);
      } finally {
        BluetoothFindDeviceClose(find);
      }
    } catch (e) {
      debugPrint('Bluetooth devices could not be listed: $e');
    } finally {
      calloc.free(params);
      calloc.free(info);
    }
    return devices;
  }

  /// Windows' "Remove device": the pairing and the cached service records go.
  @override
  bool remove(PairedDevice device) {
    final address = calloc<BLUETOOTH_ADDRESS>();
    try {
      address.ref.Anonymous.ullLong = device.address;
      final result = BluetoothRemoveDevice(address);
      if (result != 0) debugPrint('BluetoothRemoveDevice: $result');
      return result == 0;
    } catch (e) {
      debugPrint('BluetoothRemoveDevice failed: $e');
      return false;
    } finally {
      calloc.free(address);
    }
  }

  @override
  Future<bool> openSettings() async {
    try {
      // ShellExecute; `explorer <uri>` has opened the wrong thing before
      // (openInBrowser).
      return await launchUrl(
        settingsPage,
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      debugPrint('Could not open $settingsPage: $e');
      return false;
    }
  }
}
