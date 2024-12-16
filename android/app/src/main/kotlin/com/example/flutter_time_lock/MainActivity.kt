package com.example.flutter_time_lock

import android.content.Intent
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.content.DialogInterface
import androidx.appcompat.app.AlertDialog
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterFragmentActivity() {
    private val CHANNEL = "com.example.flutter_time_lock/system"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "checkOverlayPermission" -> {
                    result.success(Settings.canDrawOverlays(this))
                }
                "requestOverlayPermission" -> {
                    val intent = Intent(
                        Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                        Uri.parse("package:${packageName}")
                    )
                    startActivity(intent)
                    result.success(null)
                }
                "showSystemAlert" -> {
                    if (!Settings.canDrawOverlays(this)) {
                        result.error("PERMISSION_DENIED", "Overlay permission not granted", null)
                        return@setMethodCallHandler
                    }

                    val title = call.argument<String>("title") ?: "Alert"
                    val message = call.argument<String>("message") ?: ""

                    // Ensure the dialog is shown on the main thread
                    Handler(Looper.getMainLooper()).post {
                        AlertDialog.Builder(this)
                            .setTitle(title)
                            .setMessage(message)
                            .setPositiveButton("OK") { dialog: DialogInterface, which: Int ->
                                // User confirmed the alert
                                result.success(true)
                            }
                            .setNegativeButton("Cancel") { dialog: DialogInterface, which: Int ->
                                // User canceled the alert
                                result.success(false)
                            }
                            .setCancelable(false) // Prevent dismissal by tapping outside
                            .show()
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
}
