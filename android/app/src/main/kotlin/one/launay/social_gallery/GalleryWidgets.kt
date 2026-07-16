package one.launay.social_gallery

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.BitmapFactory
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin
import java.net.URLEncoder

open class BasePhotoWidgetProvider : AppWidgetProvider() {
    protected open val layoutId: Int = R.layout.widget_photo
    protected open val imageDataKey: String = "photo_widget_image"
    protected open val titleDataKey: String = "photo_widget_title"
    protected open val clickUri: String = "socialgallery://home"

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        for (id in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, id)
        }
    }

    protected open fun buildClickUri(context: Context, appWidgetId: Int): Uri {
        return Uri.parse(clickUri)
    }

    protected fun updateAppWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
    ) {
        val views = RemoteViews(context.packageName, layoutId)
        val prefs = HomeWidgetPlugin.getData(context)
        val imagePath = resolveImagePath(prefs, appWidgetId)
        val title = resolveTitle(prefs, appWidgetId)

        if (!imagePath.isNullOrBlank()) {
            val bitmap = BitmapFactory.decodeFile(imagePath)
            if (bitmap != null) {
                views.setImageViewBitmap(R.id.widget_image, bitmap)
                views.setViewVisibility(R.id.widget_image, View.VISIBLE)
                views.setViewVisibility(R.id.widget_placeholder, View.GONE)
            } else {
                views.setViewVisibility(R.id.widget_image, View.GONE)
                views.setViewVisibility(R.id.widget_placeholder, View.VISIBLE)
            }
        } else {
            views.setViewVisibility(R.id.widget_image, View.GONE)
            views.setViewVisibility(R.id.widget_placeholder, View.VISIBLE)
        }

        if (!title.isNullOrBlank()) {
            views.setTextViewText(R.id.widget_title, title)
            views.setViewVisibility(R.id.widget_title, View.VISIBLE)
        } else {
            views.setViewVisibility(R.id.widget_title, View.GONE)
        }

        val intent = Intent(Intent.ACTION_VIEW, buildClickUri(context, appWidgetId)).apply {
            setPackage(context.packageName)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val pending = PendingIntent.getActivity(
            context,
            appWidgetId,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        views.setOnClickPendingIntent(R.id.widget_root, pending)
        appWidgetManager.updateAppWidget(appWidgetId, views)
    }

    protected open fun resolveImagePath(prefs: SharedPreferences, appWidgetId: Int): String? {
        return prefs.getString(imageDataKey, null)
            ?: prefs.getString("${imageDataKey}_$appWidgetId", null)
    }

    protected open fun resolveTitle(prefs: SharedPreferences, appWidgetId: Int): String? {
        return prefs.getString(titleDataKey, null)
            ?: prefs.getString("${titleDataKey}_$appWidgetId", null)
    }
}

class FolderPhotoWidgetProvider : BasePhotoWidgetProvider() {
    override val imageDataKey = "folder_widget_image"
    override val titleDataKey = "folder_widget_title"
    override val clickUri = "socialgallery://folder"

    override fun buildClickUri(context: Context, appWidgetId: Int): Uri {
        val prefs = context.getSharedPreferences(
            "FlutterSharedPreferences",
            Context.MODE_PRIVATE,
        )
        val path = prefs.getString("flutter.sg_folder_widget_${appWidgetId}_folderPath", null)
        return if (!path.isNullOrBlank()) {
            Uri.parse(
                "socialgallery://folder?path=${URLEncoder.encode(path, "UTF-8")}",
            )
        } else {
            Uri.parse("socialgallery://widgets/folder-config?widgetId=$appWidgetId")
        }
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        for (id in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, id)
        }
    }

    override fun resolveImagePath(prefs: SharedPreferences, appWidgetId: Int): String? {
        return prefs.getString("folder_widget_image_$appWidgetId", null)
            ?: prefs.getString(imageDataKey, null)
    }

    override fun resolveTitle(prefs: SharedPreferences, appWidgetId: Int): String? {
        return prefs.getString("folder_widget_title_$appWidgetId", null)
            ?: prefs.getString(titleDataKey, null)
    }
}

class FavoritesPhotoWidgetProvider : BasePhotoWidgetProvider() {
    override val imageDataKey = "favorites_widget_image"
    override val titleDataKey = "favorites_widget_title"
    override val clickUri = "socialgallery://favorites"
}

class OnThisDayPhotoWidgetProvider : BasePhotoWidgetProvider() {
    override val imageDataKey = "on_this_day_widget_image"
    override val titleDataKey = "on_this_day_widget_title"
    override val clickUri = "socialgallery://gallery"
}

class OrganizeGlanceWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        val prefs = HomeWidgetPlugin.getData(context)
        val count = prefs.getString("organize_glance_count", "0") ?: "0"
        val label = prefs.getString("organize_glance_label", "to organize") ?: "to organize"

        for (id in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_organize_glance)
            views.setTextViewText(R.id.widget_count, count)
            views.setTextViewText(R.id.widget_label, label)
            val intent = Intent(
                Intent.ACTION_VIEW,
                Uri.parse("socialgallery://organize"),
            ).apply {
                setPackage(context.packageName)
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val pending = PendingIntent.getActivity(
                context,
                id,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            views.setOnClickPendingIntent(R.id.widget_root, pending)
            appWidgetManager.updateAppWidget(id, views)
        }
    }
}
