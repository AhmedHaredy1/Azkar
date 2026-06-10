package com.ahmedharedy.azkar

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.os.Build
import android.os.IBinder
import android.os.PowerManager
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat

/**
 * Foreground service that plays the selected adhan MP3 when triggered by
 * AdhanAlarmReceiver. Runs as a media-playback foreground service so Android
 * doesn't kill it mid-adhan, and acquires a partial wake lock so the device
 * stays awake long enough to finish playback (~3-5 minutes for a full adhan).
 */
class AdhanPlayerService : Service() {
    companion object {
        const val CHANNEL_ID = "adhan_playback"
        const val FOREGROUND_ID = 9999
        const val EXTRA_MP3_PATH = "mp3_path"
        const val EXTRA_PRAYER = "prayer"
        const val ACTION_STOP = "com.ahmedharedy.azkar.ACTION_STOP_ADHAN"
        private const val TAG = "AdhanPlayerService"
        private const val WAKE_LOCK_TAG = "azkar:adhan_playback"
        private const val WAKE_LOCK_TIMEOUT_MS = 10 * 60 * 1000L // 10 min ceiling
    }

    private var mediaPlayer: MediaPlayer? = null
    private var wakeLock: PowerManager.WakeLock? = null
    private var stopReceiver: BroadcastReceiver? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_STOP) {
            stopPlayback()
            stopSelf()
            return START_NOT_STICKY
        }

        val mp3Path = intent?.getStringExtra(EXTRA_MP3_PATH)
        val prayer = intent?.getStringExtra(EXTRA_PRAYER) ?: ""

        createChannel()
        startForeground(FOREGROUND_ID, buildNotification(prayer))

        if (mp3Path.isNullOrEmpty()) {
            stopSelf()
            return START_NOT_STICKY
        }

        acquireWakeLock()
        registerStopTriggers()
        playAdhan(mp3Path)
        return START_NOT_STICKY
    }

    /**
     * Register listeners that stop playback on user interaction:
     *  - Screen off (lock button pressed)
     *  - Volume button pressed (any stream volume change)
     */
    private fun registerStopTriggers() {
        if (stopReceiver != null) return
        val receiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                when (intent?.action) {
                    Intent.ACTION_SCREEN_OFF -> stopAndExit()
                    "android.media.VOLUME_CHANGED_ACTION" -> stopAndExit()
                }
            }
        }
        val filter = IntentFilter().apply {
            addAction(Intent.ACTION_SCREEN_OFF)
            addAction("android.media.VOLUME_CHANGED_ACTION")
        }
        try {
            ContextCompat.registerReceiver(
                this,
                receiver,
                filter,
                ContextCompat.RECEIVER_EXPORTED,
            )
            stopReceiver = receiver
        } catch (e: Throwable) {
            Log.w(TAG, "registerStopTriggers failed", e)
        }
    }

    private fun unregisterStopTriggers() {
        val r = stopReceiver ?: return
        try {
            unregisterReceiver(r)
        } catch (_: Throwable) {}
        stopReceiver = null
    }

    private fun stopAndExit() {
        stopPlayback()
        stopSelf()
    }

    private fun createChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val nm = getSystemService(NotificationManager::class.java)
            if (nm.getNotificationChannel(CHANNEL_ID) == null) {
                val ch = NotificationChannel(
                    CHANNEL_ID,
                    "تشغيل الأذان",
                    NotificationManager.IMPORTANCE_LOW,
                ).apply {
                    description = "يعرض إشعارًا أثناء تشغيل الأذان"
                    setSound(null, null)
                    enableVibration(false)
                    setShowBadge(false)
                }
                nm.createNotificationChannel(ch)
            }
        }
    }

    private fun buildNotification(prayer: String): Notification {
        val stopIntent = Intent(this, AdhanPlayerService::class.java).apply {
            action = ACTION_STOP
        }
        val stopPI = PendingIntent.getService(
            this,
            0,
            stopIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val openAppIntent = packageManager.getLaunchIntentForPackage(packageName)
        val contentPI = if (openAppIntent != null) {
            PendingIntent.getActivity(
                this,
                1,
                openAppIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
        } else {
            null
        }

        val title = if (prayer.isNotEmpty()) "أذان $prayer" else "الأذان"

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_media_play)
            .setContentTitle(title)
            .setContentText("يتم الآن تشغيل الأذان")
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setContentIntent(contentPI)
            .addAction(android.R.drawable.ic_media_pause, "إيقاف", stopPI)
            .build()
    }

    private fun acquireWakeLock() {
        try {
            val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
            val wl = pm.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, WAKE_LOCK_TAG)
            wl.setReferenceCounted(false)
            wl.acquire(WAKE_LOCK_TIMEOUT_MS)
            wakeLock = wl
        } catch (e: Throwable) {
            Log.w(TAG, "wake lock acquire failed", e)
        }
    }

    private fun releaseWakeLock() {
        try {
            wakeLock?.takeIf { it.isHeld }?.release()
        } catch (_: Throwable) {}
        wakeLock = null
    }

    private fun playAdhan(mp3Path: String) {
        try {
            val mp = MediaPlayer()
            mp.setAudioAttributes(
                AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_ALARM)
                    .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                    .build(),
            )
            mp.setDataSource(mp3Path)
            mp.setOnPreparedListener { it.start() }
            mp.setOnCompletionListener {
                stopPlayback()
                stopSelf()
            }
            mp.setOnErrorListener { _, what, extra ->
                Log.w(TAG, "MediaPlayer error what=$what extra=$extra")
                stopPlayback()
                stopSelf()
                true
            }
            mp.prepareAsync()
            mediaPlayer = mp
        } catch (e: Throwable) {
            Log.e(TAG, "playAdhan error", e)
            stopSelf()
        }
    }

    private fun stopPlayback() {
        try {
            mediaPlayer?.let {
                if (it.isPlaying) it.stop()
                it.release()
            }
        } catch (_: Throwable) {}
        mediaPlayer = null
        unregisterStopTriggers()
        releaseWakeLock()
    }

    override fun onDestroy() {
        stopPlayback()
        super.onDestroy()
    }
}
