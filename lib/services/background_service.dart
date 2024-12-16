import 'package:flutter_background/flutter_background.dart';
import 'dart:async';
import 'package:flutter/services.dart';

class BackgroundService {
  static const platform = MethodChannel('com.example.flutter_time_lock/system');
  static Timer? _timer;
  static const String TAG = "BackgroundService";

  static Future<void> initialize() async {
    final androidConfig = FlutterBackgroundAndroidConfig(
      notificationTitle: "Flutter Time Lock",
      notificationText: "Running in background",
      notificationImportance: AndroidNotificationImportance.high,
      showBadge: true,
    );

    bool initialized =
        await FlutterBackground.initialize(androidConfig: androidConfig);
    if (!initialized) {
      print('$TAG: Failed to initialize FlutterBackground');
      // Try to initialize with minimal config if initial attempt fails
      final fallbackConfig = FlutterBackgroundAndroidConfig(
        notificationTitle: "Flutter Time Lock",
        notificationText: "Running in background",
        notificationImportance: AndroidNotificationImportance.high,
        showBadge: false,
      );
      initialized =
          await FlutterBackground.initialize(androidConfig: fallbackConfig);
      if (!initialized) {
        print(
            '$TAG: Failed to initialize FlutterBackground with fallback config');
      }
    }
  }

  static Future<void> startService(Map<String, dynamic> config) async {
    try {
      bool hasPermissions = await FlutterBackground.hasPermissions;
      if (!hasPermissions) {
        print('$TAG: Background execution permission not granted');
        return;
      }

      bool enabled = await FlutterBackground.enableBackgroundExecution();
      if (!enabled) {
        print('$TAG: Failed to enable background execution');
        return;
      }

      // Parse interval with a default value of 20 seconds if invalid
      int intervalMinutes = 1;
      try {
        if (config['lockInterval'] != null &&
            config['lockInterval'].isNotEmpty) {
          intervalMinutes = int.parse(config['lockInterval']);
        }
      } catch (e) {
        print('$TAG: Invalid interval value, using default: $e');
      }

      // Convert minutes to seconds
      int intervalSeconds = intervalMinutes * 60;

      // Cancel existing timer if any
      _timer?.cancel();

      // Create a periodic timer that will show the alert
      _timer =
          Timer.periodic(Duration(seconds: intervalSeconds), (timer) async {
        // Ensure we have overlay permission before showing alert
        bool hasPermission = await _ensureOverlayPermission();
        if (hasPermission) {
          // Try multiple times to show the alert to ensure delivery
          for (int i = 0; i < 3; i++) {
            try {
              await _showSystemAlert('Lock Alert', 'Time to lock the device!');
              break; // Break if successful
            } catch (e) {
              print('$TAG: Attempt $i to show alert failed: $e');
              await Future.delayed(Duration(seconds: 1)); // Wait before retry
            }
          }
        } else {
          print('$TAG: Cannot show alert - overlay permission not granted');
        }
      });

      print(
          '$TAG: Background service started with interval: $intervalSeconds seconds');
    } catch (e) {
      print('$TAG: Error starting background service: $e');
    }
  }

  static Future<void> resetService(Map<String, dynamic> config) async {
    _timer?.cancel();
    await startService(config);
  }

  static Future<bool> _ensureOverlayPermission() async {
    try {
      bool hasPermission =
          await platform.invokeMethod('checkOverlayPermission');
      if (!hasPermission) {
        await platform.invokeMethod('requestOverlayPermission');
        // Check again after request
        hasPermission = await platform.invokeMethod('checkOverlayPermission');
      }
      return hasPermission;
    } catch (e) {
      print('$TAG: Error checking overlay permission: $e');
      return false;
    }
  }

  static Future<void> _showSystemAlert(String title, String message) async {
    try {
      final bool? result = await platform.invokeMethod(
          'showSystemAlert', {'title': title, 'message': message});
      if (result == false) {
        throw PlatformException(
            code: 'ALERT_DISMISSED',
            message: 'Alert was dismissed or failed to show');
      }
    } on PlatformException catch (e) {
      print("$TAG: Failed to show system alert: ${e.message}");
      if (e.code == 'PERMISSION_DENIED') {
        await _ensureOverlayPermission();
      }
      rethrow; // Rethrow to allow retry in startService
    } catch (e) {
      print('$TAG: Unexpected error showing system alert: $e');
      rethrow; // Rethrow to allow retry in startService
    }
  }

  static void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}
