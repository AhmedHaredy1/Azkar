package com.ahmedharedy.azkar

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : AudioServiceActivity() {
    private val recoveryChannelName = "com.ahmedharedy.azkar/notification_recovery"
    private val adhanChannelName = "com.ahmedharedy.azkar/adhan_alarm"

    private val adhanPrefsName = "adhan_alarms"
    private val adhanPrefsIdsKey = "scheduled_adhan_ids"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Recovery bridge for notification-plugin SharedPreferences. An earlier
        // build scheduled notifications with a custom URI sound that the
        // plugin can no longer deserialize, so every call throws
        // `Missing type parameter`. Clearing the plugin's prefs file wipes
        // those stale records in-place (both on disk and in the in-memory
        // SharedPreferences cache the plugin reads from).
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, recoveryChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "clearNotificationStorage" -> {
                        val cleared = clearFlutterLocalNotificationsPrefs()
                        result.success(cleared)
                    }
                    else -> result.notImplemented()
                }
            }

        // Adhan alarm bridge. AlarmManager + AdhanAlarmReceiver +
        // AdhanPlayerService is the only reliable way to play the user's
        // selected adhan MP3 when the app is backgrounded or killed —
        // flutter_local_notifications can't reliably use app-private file
        // URIs as a channel sound on modern Android.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, adhanChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "schedule" -> {
                        val id = call.argument<Int>("id") ?: -1
                        val triggerAt = (call.argument<Number>("triggerAtMs"))?.toLong() ?: 0L
                        val mp3Path = call.argument<String>("mp3Path") ?: ""
                        val prayer = call.argument<String>("prayer") ?: ""
                        if (id < 0 || triggerAt <= 0L || mp3Path.isEmpty()) {
                            result.success(false)
                        } else {
                            result.success(scheduleAdhan(id, triggerAt, mp3Path, prayer))
                        }
                    }
                    "cancel" -> {
                        val id = call.argument<Int>("id") ?: -1
                        result.success(if (id < 0) false else cancelAdhan(id))
                    }
                    "cancelAll" -> {
                        result.success(cancelAllAdhans())
                    }
                    "stopPlayback" -> {
                        val intent = Intent(applicationContext, AdhanPlayerService::class.java)
                            .apply { action = AdhanPlayerService.ACTION_STOP }
                        try {
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                                applicationContext.startForegroundService(intent)
                            } else {
                                applicationContext.startService(intent)
                            }
                            result.success(true)
                        } catch (_: Throwable) {
                            result.success(false)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun scheduleAdhan(
        id: Int,
        triggerAtMs: Long,
        mp3Path: String,
        prayer: String,
    ): Boolean {
        val am = applicationContext.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(applicationContext, AdhanAlarmReceiver::class.java).apply {
            putExtra(AdhanAlarmReceiver.EXTRA_MP3_PATH, mp3Path)
            putExtra(AdhanAlarmReceiver.EXTRA_PRAYER, prayer)
        }
        val pi = PendingIntent.getBroadcast(
            applicationContext,
            id,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                if (am.canScheduleExactAlarms()) {
                    am.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAtMs, pi)
                } else {
                    am.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAtMs, pi)
                }
            } else {
                am.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAtMs, pi)
            }
            rememberAdhanId(id)
            true
        } catch (_: Throwable) {
            false
        }
    }

    private fun cancelAdhan(id: Int): Boolean {
        val am = applicationContext.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(applicationContext, AdhanAlarmReceiver::class.java)
        val pi = PendingIntent.getBroadcast(
            applicationContext,
            id,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        return try {
            am.cancel(pi)
            pi.cancel()
            forgetAdhanId(id)
            true
        } catch (_: Throwable) {
            false
        }
    }

    private fun cancelAllAdhans(): Boolean {
        val prefs = applicationContext.getSharedPreferences(adhanPrefsName, Context.MODE_PRIVATE)
        val ids = prefs.getStringSet(adhanPrefsIdsKey, emptySet()) ?: emptySet()
        for (sid in ids) sid.toIntOrNull()?.let { cancelAdhan(it) }
        prefs.edit().remove(adhanPrefsIdsKey).apply()
        return true
    }

    private fun rememberAdhanId(id: Int) {
        val prefs = applicationContext.getSharedPreferences(adhanPrefsName, Context.MODE_PRIVATE)
        val set = (prefs.getStringSet(adhanPrefsIdsKey, emptySet()) ?: emptySet()).toMutableSet()
        set.add(id.toString())
        prefs.edit().putStringSet(adhanPrefsIdsKey, set).apply()
    }

    private fun forgetAdhanId(id: Int) {
        val prefs = applicationContext.getSharedPreferences(adhanPrefsName, Context.MODE_PRIVATE)
        val set = (prefs.getStringSet(adhanPrefsIdsKey, emptySet()) ?: emptySet()).toMutableSet()
        set.remove(id.toString())
        prefs.edit().putStringSet(adhanPrefsIdsKey, set).apply()
    }

    private fun clearFlutterLocalNotificationsPrefs(): Boolean {
        var touched = false

        // 1. Clear known SharedPreferences files used by the plugin.
        try {
            val names = listOf(
                "FlutterLocalNotificationsPlugin",
                "flutter_local_notifications_plugin",
                "notifications",
            )
            for (name in names) {
                val prefs = applicationContext.getSharedPreferences(
                    name,
                    Context.MODE_PRIVATE,
                )
                if (prefs.all.isNotEmpty()) {
                    prefs.edit().clear().commit()
                    touched = true
                }
            }
        } catch (_: Throwable) {}

        // 2. Delete the plugin's JSON file in the app's files dir. v18 stores
        //    scheduled notifications in `<filesDir>/scheduled_notifications`
        //    (no extension). Older/newer versions may use different names —
        //    delete anything that looks like notification persistence.
        try {
            val filesDir = applicationContext.filesDir
            val files = filesDir.listFiles() ?: emptyArray()
            for (f in files) {
                val n = f.name.lowercase()
                if (f.isFile && (
                    n.contains("scheduled_notifications") ||
                    n.contains("notification_data") ||
                    n == "notifications" ||
                    n == "notifications.json"
                )) {
                    if (f.delete()) touched = true
                }
            }
        } catch (_: Throwable) {}

        return touched
    }
}
