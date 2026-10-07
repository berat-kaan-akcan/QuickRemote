package com.quickremote.wear.hid

/** A computer the watch can be a keyboard for: a bonded Bluetooth device. */
data class Host(val address: String, val name: String)

sealed interface HidState {
    /** No session: the service is not running. */
    data object Off : HidState

    /** Waiting for the HID profile and the registration. */
    data object Starting : HidState

    /** No Bluetooth, or the watch does not offer the HID Device profile. */
    data object Unsupported : HidState

    data object BluetoothOff : HidState

    /** Android refused the registration: another app is a Bluetooth keyboard now. */
    data object Unavailable : HidState

    /** Registered: trying [target], or (null) waiting for a computer to connect. */
    data class Waiting(val target: Host?) : HidState

    data class Connected(val host: Host) : HidState

    /**
     * [host] drops the link at once. It was paired while the watch had no HID
     * record, so it does not know the watch is a keyboard and refuses it until
     * it pairs again.
     */
    data class Refused(val host: Host) : HidState
}
