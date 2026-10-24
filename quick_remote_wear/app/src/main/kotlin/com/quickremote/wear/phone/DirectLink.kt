package com.quickremote.wear.phone

import android.Manifest
import android.annotation.SuppressLint
import android.bluetooth.BluetoothClass
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothManager
import android.bluetooth.BluetoothSocket
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.os.Handler
import android.os.HandlerThread
import android.os.Looper
import android.util.Log
import androidx.core.content.ContextCompat
import java.io.DataInputStream
import java.io.IOException
import java.io.OutputStream
import java.util.UUID

/**
 * A Bluetooth socket of the watch app's own to the phone app, for the laser
 * only. The Data Layer delivers messages when it sees fit (measured: 26 to
 * 31 a second with gaps of 80 to 270 ms several times a second); a socket
 * carries each movement as it is written. The two are bonded already, so
 * nothing is paired, but the watch needs the "nearby devices" permission.
 * Without it, or without the phone's end (WearDirect.kt there), [connected]
 * stays false and the laser goes over the Data Layer as before.
 *
 * Frames are [WearProtocol.FRAME_SIZE] bytes: a type and eight bytes.
 */
class DirectLink(
    context: Context,
    private val onMoved: () -> Unit,
    private val onPong: (ByteArray) -> Unit,
) {
    private val context = context.applicationContext
    private val main = Handler(Looper.getMainLooper())

    /**
     * Writes happen on a thread of their own (a socket's write blocks while
     * the link is busy), started by [open] and ended by [close].
     */
    @Volatile
    private var writes: Handler? = null

    /** Counts [open] and [close]: a connecting thread from before a close gives up. */
    @Volatile
    private var session = 0

    @Volatile
    private var socket: BluetoothSocket? = null

    @Volatile
    private var out: OutputStream? = null

    val connected: Boolean get() = out != null

    fun permitted(): Boolean =
        Build.VERSION.SDK_INT < Build.VERSION_CODES.S ||
            ContextCompat.checkSelfPermission(context, Manifest.permission.BLUETOOTH_CONNECT) ==
            PackageManager.PERMISSION_GRANTED

    /** Connects to the phone called [phoneName], and again whenever the socket is lost, until [close]. */
    fun open(phoneName: String?) {
        close()
        if (!permitted()) return
        val mine = session
        writes = Handler(HandlerThread("QuickRemoteDirect").apply { start() }.looper)
        Thread({ run(mine, phoneName) }, "QuickRemoteDirectReader").start()
    }

    @Synchronized
    fun close() {
        session++
        out = null
        try {
            socket?.close()
        } catch (_: IOException) {
        }
        socket = null
        writes?.looper?.quitSafely()
        writes = null
    }

    /**
     * Makes [connection] the session's socket, unless [close] came since
     * [mine] began: then the socket is closed and false returned. Under the
     * same lock as [close], so a closed session never gets a socket.
     */
    @Synchronized
    private fun adopt(mine: Int, connection: BluetoothSocket, stream: OutputStream): Boolean {
        if (mine != session) return false
        socket = connection
        out = stream
        return true
    }

    fun move(bytes: ByteArray) = write(WearProtocol.FRAME_MOVE, bytes)

    fun ping(bytes: ByteArray) = write(WearProtocol.FRAME_PING, bytes)

    private fun write(type: Int, payload: ByteArray) {
        val to = out ?: return
        val thread = writes ?: return
        val frame = ByteArray(WearProtocol.FRAME_SIZE)
        frame[0] = type.toByte()
        payload.copyInto(frame, 1, 0, minOf(payload.size, WearProtocol.FRAME_SIZE - 1))
        thread.post {
            try {
                to.write(frame)
                to.flush()
            } catch (_: IOException) {
                // The reader notices the lost socket and connects again.
            }
        }
    }

    @SuppressLint("MissingPermission") // open() checks it
    private fun run(mine: Int, phoneName: String?) {
        while (mine == session) {
            val connection = connect(phoneName)
            if (connection == null) {
                Thread.sleep(RETRY_MS)
                continue
            }
            try {
                val input = DataInputStream(connection.inputStream)
                if (!adopt(mine, connection, connection.outputStream)) return
                Log.d(TAG, "Direct link open")
                val frame = ByteArray(WearProtocol.FRAME_SIZE)
                while (true) {
                    input.readFully(frame)
                    when (frame[0].toInt()) {
                        WearProtocol.FRAME_MOVED -> main.post(onMoved)
                        WearProtocol.FRAME_PONG -> frame.copyOfRange(1, frame.size).let { main.post { onPong(it) } }
                    }
                }
            } catch (e: IOException) {
                Log.d(TAG, "Direct link lost: ${e.message}")
            } catch (e: SecurityException) {
                // "Nearby devices" was taken back while the link ran.
                Log.d(TAG, "Direct link not permitted: ${e.message}")
            } finally {
                if (mine == session) out = null
                try {
                    connection.close()
                } catch (_: IOException) {
                }
            }
        }
    }

    /** The phone is the bonded device with the Data Layer node's name, or else any bonded phone that has the service. */
    @SuppressLint("MissingPermission")
    private fun connect(phoneName: String?): BluetoothSocket? {
        val adapter = context.getSystemService(BluetoothManager::class.java)?.adapter ?: return null
        val bonded = try {
            adapter.bondedDevices.orEmpty()
        } catch (_: SecurityException) {
            return null
        }
        val candidates = bonded.filter { it.name == phoneName } +
            bonded.filter { it.name != phoneName && it.bluetoothClass?.majorDeviceClass == BluetoothClass.Device.Major.PHONE }
        for (device: BluetoothDevice in candidates) {
            val attempt = try {
                device.createRfcommSocketToServiceRecord(UUID.fromString(WearProtocol.DIRECT_UUID))
            } catch (_: IOException) {
                continue
            } catch (_: SecurityException) {
                return null
            }
            try {
                attempt.connect()
                return attempt
            } catch (e: SecurityException) {
                attempt.close()
                return null
            } catch (e: IOException) {
                Log.d(TAG, "No direct link to ${device.name}: ${e.message}")
                try {
                    attempt.close()
                } catch (_: IOException) {
                }
            }
        }
        return null
    }

    private companion object {
        const val TAG = "QuickRemoteLink"
        const val RETRY_MS = 5_000L
    }
}
