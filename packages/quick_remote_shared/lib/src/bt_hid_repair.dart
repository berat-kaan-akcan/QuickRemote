/// The phone's Bluetooth remote (BT HID mode) connects to this RFCOMM service
/// on the PC when the computer refuses it as a keyboard.
///
/// A computer reads the phone's SDP records when pairing, and afterwards only
/// when it starts a connection itself. Paired while QuickRemote's HID record
/// was not registered (e.g. earlier, for audio), it does not know the phone is
/// a keyboard and refuses the HID connection, and nothing the phone can do
/// makes it read the records again. QuickRemote PC offers this service and,
/// when the phone connects to it, makes the computer read the phone's records
/// again (on Linux; Windows has no counterpart yet).
class BtHidRepair {
  BtHidRepair._();

  /// Service class UUID of the RFCOMM service.
  static const serviceUuid = 'e0090ea5-ac0f-406f-ba41-719a668817b7';
}
