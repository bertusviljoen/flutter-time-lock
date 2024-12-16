package com.example.flutter_time_lock

import android.content.Intent
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
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
                    
                    Handler(Looper.getMainLooper()).post {
                        BackgroundService.showSystemAlert(title, message)
                    }
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        startBackgroundService()
    }

    private fun startBackgroundService() {
        val intent = Intent(this, BackgroundService::class.java)
        startService(intent)
    }
}
