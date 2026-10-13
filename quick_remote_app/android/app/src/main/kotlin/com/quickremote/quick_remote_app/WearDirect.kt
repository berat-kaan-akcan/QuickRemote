package com.quickremote.quick_remote_app

import android.Manifest
import android.annotation.SuppressLint
import android.bluetooth.BluetoothManager
import android.bluetooth.BluetoothServerSocket
import android.bluetooth.BluetoothSocket
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.util.Log
import java.io.DataInputStream
import java.io.IOException
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.util.UUID

/**
 * The phone's end of the watch app's own Bluetooth socket (DirectLink.kt in
 * quick_remote_wear), which carries the laser's movement past the Data
 * Layer. Listens while the app runs; every movement is answered at once, as
 * WearRelay answers a movement message, and handed to it.
 */
object WearDirect {
    private const val TAG = "QuickRemoteWear"

    // Shared with the watch (WearProtocol.kt there).
    const val DIRECT_UUID = "87ee80c8-0bb4-41b3-b323-c934438d4992"
    private const val FRAME_SIZE = 9
    private const val FRAME_MOVE = 1
    private const val FRAME_MOVED = 2
    private const val FRAME_PING = 3
    private const val FRAME_PONG = 4

    @Volatile
    private var server: BluetoothServerSocket? = null

    @Volatile
    private var client: BluetoothSocket? = null

    /** Starts listening. Does nothing without Bluetooth or its permission. */
    @SuppressLint("MissingPermission")
    fun start(context: Context) {
        if (server != null) return
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S &&
            context.checkSelfPermission(Manifest.permission.BLUETOOTH_CONNECT) != PackageManager.PERMISSION_GRANTED
        ) {
            return
        }
        val adapter = context.getSystemService(BluetoothManager::class.java)?.adapter ?: return
        val listening = try {
            adapter.listenUsingRfcommWithServiceRecord("QuickRemote watch", UUID.fromString(DIRECT_UUID))
        } catch (e: Exception) {
            // Bluetooth is off (IOException) or the permission went (SecurityException).
            Log.d(TAG, "No direct link for the watch: ${e.message}")
            return
        }
        server = listening
        Thread({ accept(listening) }, "QuickRemoteWearDirect").start()
    }

    fun stop() {
        close(server)
        server = null
        close(client)
        client = null
    }

    private fun accept(listening: BluetoothServerSocket) {
        while (server === listening) {
            val socket = try {
                listening.accept()
            } catch (_: IOException) {
                break
            }
            client = socket
            Log.d(TAG, "Watch connected directly")
            serve(socket)
            close(socket)
        }
    }

    private fun serve(socket: BluetoothSocket) {
        try {
            val input = DataInputStream(socket.inputStream)
            val output = socket.outputStream
            val frame = ByteArray(FRAME_SIZE)
            val moved = ByteArray(FRAME_SIZE).also { it[0] = FRAME_MOVED.toByte() }
            while (true) {
                input.readFully(frame)
                when (frame[0].toInt()) {
                    FRAME_MOVE -> {
                        output.write(moved)
                        output.flush()
                        val bytes = ByteBuffer.wrap(frame, 1, 8).order(ByteOrder.LITTLE_ENDIAN)
                        WearRelay.onMove(bytes.float.toDouble(), bytes.float.toDouble())
                    }
                    FRAME_PING -> {
                        frame[0] = FRAME_PONG.toByte()
                        output.write(frame)
                        output.flush()
                    }
                }
            }
        } catch (e: IOException) {
            Log.d(TAG, "Watch's direct link closed: ${e.message}")
        }
    }

    private fun close(what: java.io.Closeable?) {
        try {
            what?.close()
        } catch (_: IOException) {
        }
    }
}
