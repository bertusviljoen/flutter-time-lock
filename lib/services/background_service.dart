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

      // Parse unlockDuration and lockTimeout with default values if invalid
      int unlockDuration = 5;
      int lockTimeout = 5;
      try {
        if (config['unlockDuration'] != null) {
          unlockDuration = int.parse(config['unlockDuration'].toString());
        }
        if (config['lockTimeout'] != null) {
          lockTimeout = int.parse(config['lockTimeout'].toString());
        }
      } catch (e) {
        print(
            '$TAG: Invalid unlockDuration or lockTimeout value, using default: $e');
      }

      // Cancel existing timer if any
      _timer?.cancel();

      // Create a periodic timer that will show the alert
      _timer = Timer.periodic(Duration(minutes: 1), (timer) async {
        // Ensure we have overlay permission before showing alert
        bool hasPermission = await _ensureOverlayPermission();
        if (hasPermission) {
          DateTime now = DateTime.now();
          int currentMinute = now.minute;

          // Calculate how many complete cycles have passed in this hour
          int completedCycles = currentMinute ~/ (unlockDuration + lockTimeout);

          // Calculate the start of the current cycle
          int cycleStartMinute =
              completedCycles * (unlockDuration + lockTimeout);

          // Calculate lock period start and end for current cycle
          int lockStartMinute = cycleStartMinute + unlockDuration;
          int lockEndMinute = lockStartMinute + lockTimeout;

          print(
              '$TAG: Current minute: $currentMinute, Cycle start: $cycleStartMinute, Lock start: $lockStartMinute, Lock end: $lockEndMinute');

          // Check if current time falls within the lock period
          if (currentMinute >= lockStartMinute &&
              currentMinute < lockEndMinute &&
              lockEndMinute <= 60) {
            // Fire and forget operation - don't await the result
            _showSystemAlert('Lock Alert',
                    'Time to lock the device for $lockTimeout minutes!')
                .catchError((error) {
              print('$TAG: Error in showing system alert: $error');
            });
          } else {
            await _closeSystemAlert();
          }
        } else {
          print('$TAG: Cannot show alert - overlay permission not granted');
        }
      });

      print(
          '$TAG: Background service started with unlockDuration: $unlockDuration minutes and lockTimeout: $lockTimeout minutes');
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

  static Future<void> _closeSystemAlert() async {
    try {
      await platform.invokeMethod('closeSystemAlert');
    } catch (e) {
      print('$TAG: Error closing system alert: $e');
    }
  }

  static void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}
