package com.quickremote.wear.hid

import android.annotation.SuppressLint
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothClass
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import androidx.core.content.ContextCompat
import androidx.core.content.IntentCompat
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

/**
 * Searches for computers nearby and pairs with one: the way in when the
 * computer cannot find the watch. The computer has to be visible, which it is
 * while its Bluetooth settings are open.
 */
// Used only once the Bluetooth permissions are granted (ui/Permissions.kt).
@SuppressLint("MissingPermission")
class PcScanner(private val context: Context) {

    sealed interface Pairing {
        data object Idle : Pairing
        data class Bonding(val address: String) : Pairing
        data class Bonded(val address: String) : Pairing
        data class Failed(val address: String) : Pairing
    }

    private val _found = MutableStateFlow<List<Host>>(emptyList())

    /** Computers found by the current search, by name. */
    val found: StateFlow<List<Host>> = _found.asStateFlow()

    private val _searching = MutableStateFlow(false)
    val searching: StateFlow<Boolean> = _searching.asStateFlow()

    private val _pairing = MutableStateFlow<Pairing>(Pairing.Idle)
    val pairing: StateFlow<Pairing> = _pairing.asStateFlow()

    private val adapter: BluetoothAdapter?
        get() = context.getSystemService(BluetoothManager::class.java)?.adapter

    private var listening = false

    /** Starts a search (about 12 s), or a new one. */
    fun search() {
        val adapter = adapter?.takeIf { it.isEnabled } ?: return
        listen()
        _found.value = emptyList()
        adapter.cancelDiscovery()
        _searching.value = adapter.startDiscovery()
    }

    /** Pairs with the computer at [address]; both devices show a code to confirm. */
    fun pair(address: String) {
        val adapter = adapter ?: return
        listen()
        // A search slows pairing down.
        adapter.cancelDiscovery()
        val device = adapter.getRemoteDevice(address)
        if (device.bondState == BluetoothDevice.BOND_BONDED) {
            _pairing.value = Pairing.Bonded(address)
            return
        }
        _pairing.value = Pairing.Bonding(address)
        if (!device.createBond()) _pairing.value = Pairing.Failed(address)
    }

    fun close() {
        if (!listening) return
        listening = false
        adapter?.cancelDiscovery()
        context.unregisterReceiver(receiver)
        _searching.value = false
    }

    private fun listen() {
        if (listening) return
        listening = true
        ContextCompat.registerReceiver(
            context,
            receiver,
            IntentFilter().apply {
                addAction(BluetoothDevice.ACTION_FOUND)
                addAction(BluetoothDevice.ACTION_BOND_STATE_CHANGED)
                addAction(BluetoothAdapter.ACTION_DISCOVERY_FINISHED)
            },
            ContextCompat.RECEIVER_NOT_EXPORTED,
        )
    }

    private val receiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            when (intent.action) {
                BluetoothDevice.ACTION_FOUND -> onFound(intent)
                BluetoothAdapter.ACTION_DISCOVERY_FINISHED -> _searching.value = false
                BluetoothDevice.ACTION_BOND_STATE_CHANGED -> onBondState(intent)
            }
        }
    }

    private fun onFound(intent: Intent) {
        val device = intent.bluetoothDevice() ?: return
        val btClass = IntentCompat.getParcelableExtra(intent, BluetoothDevice.EXTRA_CLASS, BluetoothClass::class.java)
        if (!isComputer(btClass?.majorDeviceClass)) return
        val name = intent.getStringExtra(BluetoothDevice.EXTRA_NAME) ?: device.label()
        // A device is reported again when its name arrives.
        _found.value = (_found.value.filter { it.address != device.address } + Host(device.address, name))
            .sortedBy { it.name.lowercase() }
    }

    private fun onBondState(intent: Intent) {
        val device = intent.bluetoothDevice() ?: return
        val pairing = _pairing.value as? Pairing.Bonding ?: return
        if (device.address != pairing.address) return
        when (intent.getIntExtra(BluetoothDevice.EXTRA_BOND_STATE, BluetoothDevice.ERROR)) {
            BluetoothDevice.BOND_BONDED -> _pairing.value = Pairing.Bonded(device.address)
            BluetoothDevice.BOND_NONE -> _pairing.value = Pairing.Failed(device.address)
        }
    }

    companion object {
        /**
         * Computers, and devices without a class (a misconfigured Linux PC
         * reports none); phones, watches and headphones are left out.
         */
        fun isComputer(majorClass: Int?): Boolean =
            majorClass == BluetoothClass.Device.Major.COMPUTER ||
                majorClass == BluetoothClass.Device.Major.UNCATEGORIZED
    }
}
