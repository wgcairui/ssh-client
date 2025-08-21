package com.cairui.sshtools.ssh_client

import android.content.Intent
import android.net.Uri
import android.os.Build
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.cairui.sshtools.ssh_client/apk_installer"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "installApk" -> {
                    val apkFilePath = call.argument<String>("apkFilePath")
                    if (apkFilePath != null) {
                        val success = installApk(apkFilePath)
                        result.success(success)
                    } else {
                        result.error("INVALID_ARGUMENT", "APK file path is required", null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun installApk(apkFilePath: String): Boolean {
        return try {
            val apkFile = File(apkFilePath)
            if (!apkFile.exists()) {
                return false
            }

            val intent = Intent(Intent.ACTION_VIEW)
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)

            val apkUri: Uri = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                // Android 7.0 及以上使用 FileProvider
                FileProvider.getUriForFile(
                    this,
                    "$packageName.fileProvider",
                    apkFile
                )
            } else {
                // Android 7.0 以下直接使用文件路径
                Uri.fromFile(apkFile)
            }

            intent.setDataAndType(apkUri, "application/vnd.android.package-archive")
            startActivity(intent)
            true
        } catch (e: Exception) {
            e.printStackTrace()
            false
        }
    }
}
