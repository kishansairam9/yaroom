package com.auth0.yaroom

import android.content.ContentValues
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import android.util.Log
import android.webkit.MimeTypeMap
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.IOException

class MainActivity: FlutterActivity() {
    private fun getMimeType(path: String, fallback: String = "*/*"): String {
        return MimeTypeMap.getFileExtensionFromUrl(path)
                ?.run { MimeTypeMap.getSingleton().getMimeTypeFromExtension(toLowerCase()) }
                ?: fallback // You might set it to */*
    }
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "flutter_media_store"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "addItem" -> {
                    addItem(call.argument("path")!!, call.argument("name")!!)
                    result.success(null)
                }
            }
        }
    }
    private fun addItem(path: String, name: String) {
        val mimeType = getMimeType(path)
        
        val collection = if(Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            MediaStore.Downloads.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
        } else {
            MediaStore.Downloads.EXTERNAL_CONTENT_URI
        }

        val values = ContentValues().apply {
            put(MediaStore.MediaColumns.DISPLAY_NAME, name)
            put(MediaStore.MediaColumns.MIME_TYPE, mimeType)
            // put(MediaStore.MediaColumns.SIZE, getFileSize(path))

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                // put(MediaStore.MediaColumns.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS + File.separator + getString(R.string.app_name))
                put(MediaStore.MediaColumns.IS_PENDING, 1)
            }
        }

        val resolver = applicationContext.contentResolver
        val uri = resolver.insert(collection, values)!!

        try {
            resolver.openOutputStream(uri).use { os ->
                File(path).inputStream().use { it.copyTo(os!!) }
            }

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                values.clear()
                values.put(MediaStore.MediaColumns.IS_PENDING, 0)
                resolver.update(uri, values, null, null)
            }
        } catch (ex: IOException) {
            Log.e("MediaStore", ex.message, ex)
        }
    }
}
