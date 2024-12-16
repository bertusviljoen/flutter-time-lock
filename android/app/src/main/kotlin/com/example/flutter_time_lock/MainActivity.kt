package com.example.flutter_time_lock

import android.content.Intent
import android.graphics.PixelFormat
import android.net.Uri
import android.net.wifi.WifiManager
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.view.Gravity
import android.view.LayoutInflater
import android.view.View
import android.view.WindowManager
import android.widget.Button
import android.widget.TextView
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterFragmentActivity() {
    private val CHANNEL = "com.example.flutter_time_lock/system"
    private var windowManager: WindowManager? = null
    private var overlayView: View? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        windowManager = getSystemService(WINDOW_SERVICE) as WindowManager
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when {
                call.method == "checkOverlayPermission" -> {
                    result.success(Settings.canDrawOverlays(this))
                }
                call.method == "requestOverlayPermission" -> {
                    val intent = Intent(
                        Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                        Uri.parse("package:${packageName}")
                    )
                    startActivity(intent)
                    result.success(null)
                }
                call.method == "checkWifiPermission" -> {
                    result.success((applicationContext.getSystemService(WIFI_SERVICE) as WifiManager).isWifiEnabled)
                }
                call.method == "requestWifiPermission" -> {
                    val intent = Intent(
                        Settings.ACTION_WIFI_SETTINGS
                    )
                    startActivity(intent)
                    result.success(null)
                }
                call.method == "checkForegroundServicePermission" -> {
                    result.success(true) // Foreground service permission is always granted
                }
                call.method == "requestForegroundServicePermission" -> {
                    result.success(true) // Foreground service permission is always granted
                }
                call.method == "checkWakeLockPermission" -> {
                    result.success(true) // Wake lock permission is always granted
                }
                call.method == "requestWakeLockPermission" -> {
                    result.success(true) // Wake lock permission is always granted
                }
                call.method == "checkReceiveBootCompletedPermission" -> {
                    result.success(true) // Receive boot completed permission is always granted
                }
                call.method == "requestReceiveBootCompletedPermission" -> {
                    result.success(true) // Receive boot completed permission is always granted
                }
                call.method == "checkAccessWifiStatePermission" -> {
                    result.success(true) // Access WiFi state permission is always granted
                }
                call.method == "requestAccessWifiStatePermission" -> {
                    result.success(true) // Access WiFi state permission is always granted
                }
                call.method == "showSystemAlert" -> {
                    if (!Settings.canDrawOverlays(this)) {
                        result.error("PERMISSION_DENIED", "Overlay permission not granted", null)
                        return@setMethodCallHandler
                    }

                    val title = call.argument<String>("title") ?: "Alert"
                    val message = call.argument<String>("message") ?: ""

                    // Ensure the dialog is shown on the main thread
                    Handler(Looper.getMainLooper()).post {
                        showOverlayWindow(title, message) { confirmed ->
                            result.success(confirmed)
                        }
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun showOverlayWindow(title: String, message: String, callback: (Boolean) -> Unit) {
        // Remove any existing overlay first
        removeOverlayWindow()

        // Create the overlay layout
        overlayView = LayoutInflater.from(this).inflate(R.layout.overlay_alert, null)

        // Set the title and message
        overlayView?.findViewById<TextView>(R.id.alertTitle)?.text = title
        overlayView?.findViewById<TextView>(R.id.alertMessage)?.text = message

        // Set up the buttons
        overlayView?.findViewById<Button>(R.id.okButton)?.setOnClickListener {
            removeOverlayWindow()
            callback(true)
        }

        overlayView?.findViewById<Button>(R.id.cancelButton)?.setOnClickListener {
            removeOverlayWindow()
            callback(false)
        }

        // Create layout parameters for the overlay
        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
            WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED
                    or WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
                    or WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON
                    or WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD
                    or WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.CENTER
        }

        // Add the view to the window manager
        try {
            windowManager?.addView(overlayView, params)
        } catch (e: Exception) {
            e.printStackTrace()
            callback(false)
        }

        blockPackages()
    }

    private fun removeOverlayWindow() {
        try {
            if (overlayView != null) {
                windowManager?.removeView(overlayView)
                overlayView = null
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun disableWiFi() {
        try {
            val intent = Intent(Settings.Panel.ACTION_INTERNET_CONNECTIVITY)
            startActivity(intent)
            android.util.Log.d("Flutter", "Opened WiFi settings panel")
        } catch (e: Exception) {
            android.util.Log.e("Flutter", "Failed to open WiFi settings: ${e.message}", e)
        }
    }

    private fun blockPackages() {
        val blockedPackages = listOf(
            "com.google.android.youtube",
            "com.android.chrome",
            "com.google.android.play.games"
        )

        try {
            val intent = Intent(Intent.ACTION_MAIN)
            intent.addCategory(Intent.CATEGORY_HOME)
            intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
            startActivity(intent)

            // Force stop blocked apps if they're running
            val am = getSystemService(ACTIVITY_SERVICE) as android.app.ActivityManager
            for (pkg in blockedPackages) {
                try {
                    am.killBackgroundProcesses(pkg)
                } catch (e: Exception) {
                    android.util.Log.e("Flutter", "Failed to kill process: ${e.message}")
                }
            }
        } catch (e: Exception) {
            android.util.Log.e("Flutter", "Failed to block packages: ${e.message}")
        }
    }

    override fun onDestroy() {
        removeOverlayWindow()
        super.onDestroy()
    }
}
