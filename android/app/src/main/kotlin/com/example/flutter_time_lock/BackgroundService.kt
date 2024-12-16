package com.example.flutter_time_lock

import android.app.Service
import android.content.Intent
import android.os.IBinder
import android.os.Handler
import android.os.Looper

class BackgroundService : Service() {

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        // Start a new thread to run the background task
        Thread {
            // Your background task code here
            Handler(Looper.getMainLooper()).post {
                // Update UI if needed
            }
        }.start()
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? {
        return null
    }
}
