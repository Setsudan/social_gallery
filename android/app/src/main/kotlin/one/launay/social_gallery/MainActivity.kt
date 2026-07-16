package one.launay.social_gallery

import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.content.Intent
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "copyImageFile" -> {
                    val path = call.argument<String>("path")
                    if (path.isNullOrBlank()) {
                        result.error("invalid_args", "Missing path", null)
                        return@setMethodCallHandler
                    }
                    try {
                        copyImageFile(path)
                        result.success(true)
                    } catch (error: Exception) {
                        result.error("copy_failed", error.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun copyImageFile(path: String) {
        val source = File(path)
        if (!source.exists() || !source.isFile) {
            throw IllegalArgumentException("Image file not found")
        }

        val cacheDir = File(cacheDir, "clipboard").apply { mkdirs() }
        val extension = source.extension.ifBlank { "jpg" }
        val dest = File(cacheDir, "clipboard_image.$extension")
        source.copyTo(dest, overwrite = true)

        val uri = FileProvider.getUriForFile(
            this,
            "$packageName.fileprovider",
            dest,
        )
        val clip = ClipData.newUri(contentResolver, "Image", uri)
        // Persist read access for clipboard consumers.
        grantUriPermission(
            "com.android.systemui",
            uri,
            Intent.FLAG_GRANT_READ_URI_PERMISSION,
        )

        val clipboard = getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
        clipboard.setPrimaryClip(clip)
    }

    companion object {
        private const val CHANNEL = "one.launay.social_gallery/clipboard"
    }
}
