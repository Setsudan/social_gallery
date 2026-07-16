package one.launay.social_gallery

import android.appwidget.AppWidgetManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * Refreshes photo widgets when the user unlocks the device, for widgets
 * that opted into refresh-on-unlock.
 */
class WidgetUnlockReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        val action = intent?.action ?: return
        if (action != Intent.ACTION_USER_PRESENT &&
            action != Intent.ACTION_USER_UNLOCKED
        ) {
            return
        }

        val prefs = context.getSharedPreferences(
            "FlutterSharedPreferences",
            Context.MODE_PRIVATE,
        )
        val shouldRefresh = prefs.all.entries.any { (key, value) ->
            key.startsWith("flutter.sg_folder_widget_") &&
                key.endsWith("_refreshOnUnlock") &&
                value == true
        }
        if (!shouldRefresh) return

        context.sendBroadcast(
            Intent(context, FolderPhotoWidgetProvider::class.java).apply {
                this.action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
            },
        )
        context.sendBroadcast(
            Intent(context, FavoritesPhotoWidgetProvider::class.java).apply {
                this.action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
            },
        )
        context.sendBroadcast(
            Intent(context, OnThisDayPhotoWidgetProvider::class.java).apply {
                this.action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
            },
        )
    }
}
