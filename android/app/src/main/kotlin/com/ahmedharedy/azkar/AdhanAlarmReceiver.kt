package com.ahmedharedy.azkar

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log

/**
 * Broadcast receiver fired by AlarmManager at the scheduled prayer time.
 * Starts AdhanPlayerService as a foreground service so the selected adhan
 * MP3 plays even when the app is in the background or killed.
 */
class AdhanAlarmReceiver : BroadcastReceiver() {
    companion object {
        const val EXTRA_MP3_PATH = "mp3_path"
        const val EXTRA_PRAYER = "prayer"
        private const val TAG = "AdhanAlarmReceiver"
    }

    override fun onReceive(context: Context, intent: Intent) {
        val mp3Path = intent.getStringExtra(EXTRA_MP3_PATH)
        if (mp3Path.isNullOrEmpty()) {
            Log.w(TAG, "fired without mp3 path — skipping")
            return
        }
        val prayer = intent.getStringExtra(EXTRA_PRAYER) ?: ""

        val serviceIntent = Intent(context, AdhanPlayerService::class.java).apply {
            putExtra(AdhanPlayerService.EXTRA_MP3_PATH, mp3Path)
            putExtra(AdhanPlayerService.EXTRA_PRAYER, prayer)
        }

        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(serviceIntent)
            } else {
                context.startService(serviceIntent)
            }
        } catch (e: Throwable) {
            Log.e(TAG, "failed to start AdhanPlayerService", e)
        }
    }
}
