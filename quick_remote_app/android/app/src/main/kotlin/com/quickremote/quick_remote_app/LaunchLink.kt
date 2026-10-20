package com.quickremote.quick_remote_app

import android.app.Activity
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.ShortcutInfo
import android.content.pm.ShortcutManager
import android.graphics.drawable.Icon
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.service.quicksettings.TileService
import io.flutter.plugin.common.MethodChannel

/**
 * The ways into the app from outside it: the launcher's app shortcuts
 * (res/xml/shortcuts.xml and the dynamic "Connect: <PC>" one) and the Quick
 * Settings tile. Each opens MainActivity with a quickremote:// link, which
 * Dart reads over [CHANNEL] (lib/services/launch_actions.dart):
 * quickremote://connect/last, quickremote://bluetooth, quickremote://scan.
 * The links are sent only as explicit intents; MainActivity has no filter for
 * them, so a web page cannot open them.
 */
object LaunchLink {
    const val CHANNEL = "com.quickremote.quick_remote_app/launch"
    const val CONNECT_LAST = "quickremote://connect/last"

    private const val PREFS = "quickremote_launch"
    private const val KEY_LAST_PC = "last_pc"
    private const val SHORTCUT_LAST_PC = "connect_last"
    private val HOSTS = setOf("connect", "bluetooth", "scan")

    /** Whether the phone has a Wi-Fi connection to a PC; the tile shows it.
     *  Kept in memory only: a killed app is no longer connected. */
    @Volatile
    var connected = false
        private set

    /** A link not yet taken by Dart (cold start, or Dart not listening yet). */
    private var pending: String? = null
    private var channel: MethodChannel? = null

    /** The link [intent] carries, if it is one of ours. A task brought back
     *  from the recent apps carries its first intent again: not a new tap. */
    fun linkOf(intent: Intent?): String? {
        if (intent == null || intent.action != Intent.ACTION_VIEW) return null
        if (intent.flags and Intent.FLAG_ACTIVITY_LAUNCHED_FROM_HISTORY != 0) return null
        val data = intent.data ?: return null
        if (data.scheme != "quickremote" || data.host !in HOSTS) return null
        return data.toString()
    }

    /** An intent that opens MainActivity with [link], in its existing task
     *  when it has one (singleTop: onNewIntent). */
    fun intent(context: Context, link: String): Intent =
        Intent(Intent.ACTION_VIEW, Uri.parse(link), context, MainActivity::class.java)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)

    fun lastPcName(context: Context): String? =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).getString(KEY_LAST_PC, null)

    /** [restored]: the Activity was recreated, its intent was taken before. */
    fun attach(activity: Activity, channel: MethodChannel, restored: Boolean) {
        this.channel = channel
        val context = activity.applicationContext
        if (pending == null && !restored) pending = linkOf(activity.intent)
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "initialAction" -> {
                    result.success(pending)
                    pending = null
                }
                "lastPc" -> {
                    setLastPc(context, call.argument<String>("name"))
                    result.success(null)
                }
                "connected" -> {
                    setConnected(context, call.argument<Boolean>("connected") == true)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    fun detach(context: Context) {
        channel?.setMethodCallHandler(null)
        channel = null
        setConnected(context, false)
    }

    /** A link that came while the app runs: handed to Dart at once, and kept
     *  for initialAction until Dart has taken it. */
    fun onNewIntent(intent: Intent) {
        val link = linkOf(intent) ?: return
        pending = link
        channel?.invokeMethod("action", link, object : MethodChannel.Result {
            override fun success(result: Any?) {
                if (pending == link) pending = null
            }
            override fun error(code: String, message: String?, details: Any?) {}
            override fun notImplemented() {}
        })
    }

    private fun setConnected(context: Context, value: Boolean) {
        if (connected == value) return
        connected = value
        refreshTile(context)
    }

    /** The last PC's name changed: the dynamic shortcut and the tile's
     *  subtitle follow it. No name removes the shortcut. */
    private fun setLastPc(context: Context, name: String?) {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val clean = name?.trim()?.takeIf { it.isNotEmpty() }
        if (prefs.getString(KEY_LAST_PC, null) == clean) return
        prefs.edit().putString(KEY_LAST_PC, clean).apply()
        updateShortcut(context, clean)
        refreshTile(context)
    }

    private fun updateShortcut(context: Context, name: String?) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.N_MR1) return
        val manager = context.getSystemService(ShortcutManager::class.java) ?: return
        try {
            if (name == null) {
                manager.removeDynamicShortcuts(listOf(SHORTCUT_LAST_PC))
                return
            }
            val label = context.getString(R.string.shortcut_connect, name)
            val shortcut = ShortcutInfo.Builder(context, SHORTCUT_LAST_PC)
                .setShortLabel(label)
                .setLongLabel(label)
                .setIcon(Icon.createWithResource(context, R.drawable.ic_shortcut_connect))
                .setIntent(shortcutIntent(context, CONNECT_LAST))
                .setRank(0)
                .build()
            manager.dynamicShortcuts = listOf(shortcut)
        } catch (e: Exception) {
            // IllegalStateException when rate limited; the next change retries.
        }
    }

    /** Shortcut intents go through [ShortcutActivity]: the launcher starts
     *  them with CLEAR_TASK, which would end a running remote. */
    private fun shortcutIntent(context: Context, link: String): Intent =
        Intent(Intent.ACTION_VIEW, Uri.parse(link), context, ShortcutActivity::class.java)

    private fun refreshTile(context: Context) {
        try {
            TileService.requestListeningState(
                context, ComponentName(context, QuickTileService::class.java),
            )
        } catch (e: Exception) {
            // No Quick Settings on this device.
        }
    }
}

/**
 * The target of every app shortcut: passes the link on to MainActivity in its
 * own task and closes. It lives in a task of its own (manifest taskAffinity),
 * so the launcher's CLEAR_TASK clears only this one.
 */
class ShortcutActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val link = intent?.data?.toString()
        if (link != null) startActivity(LaunchLink.intent(this, link))
        finish()
    }
}
