import 'dart:io';

import 'windows_bluetooth.dart';

/// A Bluetooth device paired with this PC.
class PairedDevice {
  const PairedDevice({
    required this.name,
    required this.address,
    required this.classOfDevice,
  });

  final String name;

  /// The 48-bit address.
  final int address;
  final int classOfDevice;

  /// A phone by its Class of Device: major device class 2.
  bool get isPhone => (classOfDevice >> 8) & 0x1F == 0x02;

  /// "AA:BB:CC:DD:EE:FF".
  String get addressText => [
    for (var i = 5; i >= 0; i--)
      ((address >> (8 * i)) & 0xFF).toRadixString(16).padLeft(2, '0'),
  ].join(':').toUpperCase();

  /// The name to show: the address when the device has none.
  String get label => name.trim().isEmpty ? addressText : name.trim();
}

/// The operating system's list of paired Bluetooth devices, as far as
/// [BtRepair] needs it.
abstract class BluetoothPairing {
  /// The platform's implementation; null where pairing needs no repair from
  /// here (Linux has BluezHidRepair).
  static final BluetoothPairing? instance = Platform.isWindows
      ? WindowsBluetooth()
      : null;

  /// The devices the system remembers, in no particular order.
  List<PairedDevice> paired();

  /// Forgets [device]; false when the system refused.
  bool remove(PairedDevice device);

  /// Opens the system's Bluetooth settings, where a device is added; false
  /// when they could not be opened.
  Future<bool> openSettings();
}

/// How [BtRepair.repair] ended.
enum BtRepairOutcome {
  /// Removed, and the Bluetooth settings are open for adding it again.
  removed,

  /// Removed, but the settings did not open: the user has to open them.
  removedSettingsClosed,

  /// The system did not remove the device; nothing else was done.
  removeFailed,
}

/// Pairing the phone with the computer again, for a computer that refuses it
/// as a keyboard.
///
/// A computer reads a phone's Bluetooth services when it pairs. Windows keeps
/// refusing a phone paired while its Bluetooth remote screen was not open
/// (for audio, say); switching the HID service off and on did not help,
/// removing the phone and adding it again in Windows' settings did (tried by
/// hand on Windows 11, 2026-10-25). So the phone is removed here and Windows'
/// own settings are opened for the pairing. Pairing from code is not done:
/// docs/raporlar/WINDOWS_BT_ONARIM.md.
class BtRepair {
  const BtRepair(this._pairing);

  final BluetoothPairing _pairing;

  /// The devices to pick from: phones first, then by name.
  List<PairedDevice> candidates() {
    final devices = [..._pairing.paired()];
    devices.sort((a, b) {
      if (a.isPhone != b.isPhone) return a.isPhone ? -1 : 1;
      final byName = a.label.toLowerCase().compareTo(b.label.toLowerCase());
      return byName != 0 ? byName : a.address.compareTo(b.address);
    });
    return devices;
  }

  Future<BtRepairOutcome> repair(PairedDevice device) async {
    if (!_pairing.remove(device)) return BtRepairOutcome.removeFailed;
    return await _pairing.openSettings()
        ? BtRepairOutcome.removed
        : BtRepairOutcome.removedSettingsClosed;
  }
}
