package com.ahmedharedy.azkar

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

/**
 * Home-screen widget showing the next prayer, its time, a countdown,
 * and a short dhikr. Data is written by the Flutter side via the
 * `home_widget` package into SharedPreferences, then we read it here
 * and render it into the RemoteViews.
 */
class PrayerWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        val prefs = HomeWidgetPlugin.getData(context)
        val prayerName = prefs.getString("next_prayer_name", "—") ?: "—"
        val prayerTime = prefs.getString("next_prayer_time", "—") ?: "—"
        val countdown = prefs.getString("next_prayer_countdown", "—") ?: "—"
        val dhikr = prefs.getString("current_dhikr", "") ?: ""

        val launchIntent = context.packageManager
            .getLaunchIntentForPackage(context.packageName)
        val pendingIntent = if (launchIntent != null) {
            PendingIntent.getActivity(
                context,
                0,
                launchIntent,
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
            )
        } else null

        for (widgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.prayer_widget)
            views.setTextViewText(R.id.widget_prayer_name, prayerName)
            views.setTextViewText(R.id.widget_prayer_time, prayerTime)
            views.setTextViewText(R.id.widget_countdown, countdown)
            views.setTextViewText(R.id.widget_dhikr, dhikr)
            if (pendingIntent != null) {
                views.setOnClickPendingIntent(R.id.widget_prayer_name, pendingIntent)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
