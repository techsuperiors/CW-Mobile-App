package com.app.collectivWork

import android.content.ContentValues
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileInputStream
import java.io.IOException

class MainActivity : FlutterActivity() {
    private val downloadsChannel = "collectivwork/downloads"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            downloadsChannel
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getAndroidSdkInt" -> result.success(Build.VERSION.SDK_INT)
                "saveFileToDownloads" -> {
                    val sourcePath = call.argument<String>("sourcePath")
                    val fileName = call.argument<String>("fileName")
                    val mimeType = call.argument<String>("mimeType")
                    val subdirectory = call.argument<String>("subdirectory")

                    if (sourcePath.isNullOrBlank() || fileName.isNullOrBlank()) {
                        result.success(
                            mapOf(
                                "success" to false,
                                "error" to "Invalid file details."
                            )
                        )
                        return@setMethodCallHandler
                    }

                    result.success(
                        saveFileToDownloads(
                            sourcePath = sourcePath,
                            fileName = fileName,
                            mimeType = mimeType ?: "application/octet-stream",
                            subdirectory = subdirectory ?: "Downloads"
                        )
                    )
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun saveFileToDownloads(
        sourcePath: String,
        fileName: String,
        mimeType: String,
        subdirectory: String
    ): Map<String, Any?> {
        val sourceFile = File(sourcePath)
        if (!sourceFile.exists()) {
            return mapOf("success" to false, "error" to "Generated PDF file was not found.")
        }

        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                saveToMediaStoreDownloads(sourceFile, fileName, mimeType, subdirectory)
            } else {
                saveToLegacyDownloads(sourceFile, fileName, subdirectory)
            }
        } catch (e: Exception) {
            mapOf(
                "success" to false,
                "error" to (e.message ?: "Failed to save file to Downloads.")
            )
        }
    }

    private fun saveToMediaStoreDownloads(
        sourceFile: File,
        fileName: String,
        mimeType: String,
        subdirectory: String
    ): Map<String, Any?> {
        val resolver = applicationContext.contentResolver
        val relativePath = "${Environment.DIRECTORY_DOWNLOADS}/$subdirectory"
        val values = ContentValues().apply {
            put(MediaStore.MediaColumns.DISPLAY_NAME, fileName)
            put(MediaStore.MediaColumns.MIME_TYPE, mimeType)
            put(MediaStore.MediaColumns.RELATIVE_PATH, relativePath)
            put(MediaStore.MediaColumns.IS_PENDING, 1)
        }

        val uri = resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values)
            ?: return mapOf("success" to false, "error" to "Unable to create Downloads entry.")

        try {
            resolver.openOutputStream(uri)?.use { outputStream ->
                FileInputStream(sourceFile).use { inputStream ->
                    inputStream.copyTo(outputStream)
                }
            } ?: throw IOException("Unable to open Downloads output stream.")

            values.clear()
            values.put(MediaStore.MediaColumns.IS_PENDING, 0)
            resolver.update(uri, values, null, null)

            return mapOf(
                "success" to true,
                "uri" to uri.toString(),
                "pathHint" to "$relativePath/$fileName"
            )
        } catch (e: Exception) {
            resolver.delete(uri, null, null)
            throw e
        }
    }

    private fun saveToLegacyDownloads(
        sourceFile: File,
        fileName: String,
        subdirectory: String
    ): Map<String, Any?> {
        val downloadsRoot =
            Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
        val targetDirectory = File(downloadsRoot, subdirectory).apply {
            if (!exists()) {
                mkdirs()
            }
        }

        var targetFile = File(targetDirectory, fileName)
        if (targetFile.exists()) {
            val baseName = fileName.substringBeforeLast('.', fileName)
            val extension = fileName.substringAfterLast('.', "")
            var copyIndex = 1
            while (targetFile.exists()) {
                val candidateName =
                    if (extension.isBlank()) "$baseName ($copyIndex)"
                    else "$baseName ($copyIndex).$extension"
                targetFile = File(targetDirectory, candidateName)
                copyIndex++
            }
        }

        FileInputStream(sourceFile).use { inputStream ->
            targetFile.outputStream().use { outputStream ->
                inputStream.copyTo(outputStream)
            }
        }

        return mapOf(
            "success" to true,
            "path" to targetFile.absolutePath
        )
    }
}
