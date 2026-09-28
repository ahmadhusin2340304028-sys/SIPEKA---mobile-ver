package com.sipeka.app

import android.content.ContentValues
import android.content.Intent
import android.os.Build
import android.provider.MediaStore
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val exportChannel = "com.sipeka.app/export"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, exportChannel)
            .setMethodCallHandler { call, result ->
                if (call.method != "saveAndOpen") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }

                val bytes = call.argument<ByteArray>("bytes")
                val filename = call.argument<String>("filename")
                val mimeType = call.argument<String>("mimeType")
                if (bytes == null || filename.isNullOrBlank() || mimeType.isNullOrBlank()) {
                    result.error("INVALID_ARGUMENT", "Berkas ekspor tidak lengkap.", null)
                    return@setMethodCallHandler
                }

                try {
                    val uri = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                        val values = ContentValues().apply {
                            put(MediaStore.Downloads.DISPLAY_NAME, filename)
                            put(MediaStore.Downloads.MIME_TYPE, mimeType)
                            put(MediaStore.Downloads.RELATIVE_PATH, "Download/")
                            put(MediaStore.Downloads.IS_PENDING, 1)
                        }
                        val downloadUri = contentResolver.insert(
                            MediaStore.Downloads.EXTERNAL_CONTENT_URI,
                            values,
                        ) ?: throw IllegalStateException("Folder Download tidak tersedia.")

                        contentResolver.openOutputStream(downloadUri)?.use { it.write(bytes) }
                            ?: throw IllegalStateException("Tidak dapat menulis berkas ekspor.")
                        values.clear()
                        values.put(MediaStore.Downloads.IS_PENDING, 0)
                        contentResolver.update(downloadUri, values, null, null)
                        downloadUri
                    } else {
                        // Android lama: simpan di folder khusus aplikasi agar tetap
                        // tidak membutuhkan akses penyimpanan yang sensitif.
                        val file = File(getExternalFilesDir("Download"), filename)
                        file.parentFile?.mkdirs()
                        file.writeBytes(bytes)
                        FileProvider.getUriForFile(this, "$packageName.fileprovider", file)
                    }

                    val viewIntent = Intent(Intent.ACTION_VIEW).apply {
                        setDataAndType(uri, mimeType)
                        addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                    }
                    if (viewIntent.resolveActivity(packageManager) != null) {
                        startActivity(Intent.createChooser(viewIntent, "Buka berkas ekspor"))
                    }
                    result.success(filename)
                } catch (error: Exception) {
                    result.error("SAVE_FAILED", error.message, null)
                }
            }
    }
}
