import 'package:flutter_background/flutter_background.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import '../utils/logger.dart';

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

    try {
      bool initialized =
          await FlutterBackground.initialize(androidConfig: androidConfig);
      if (!initialized) {
        LoggerUtil.error(TAG, 'Failed to initialize FlutterBackground');
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
          LoggerUtil.error(TAG, 'Failed to initialize FlutterBackground with fallback config');
        }
      }
      await startAndroidService();
    } catch (e, stackTrace) {
      LoggerUtil.error(TAG, 'Error initializing FlutterBackground', e, stackTrace);
    }
  }

  static Future<void> startService(Map<String, dynamic> config) async {
    try {
      bool hasPermissions = await FlutterBackground.hasPermissions;
      if (!hasPermissions) {
        LoggerUtil.error(TAG, 'Background execution permission not granted');
        return;
      }

      bool enabled = await FlutterBackground.enableBackgroundExecution();
      if (!enabled) {
        LoggerUtil.error(TAG, 'Failed to enable background execution');
        return;
      }

      // Parse unlockDuration and lockTimeout with default values if invalid
      int unlockDuration = 1;
      int lockTimeout = 1;
      try {
        if (config['unlockDuration'] != null) {
          unlockDuration = int.parse(config['unlockDuration'].toString());
        }
        if (config['lockTimeout'] != null) {
          lockTimeout = int.parse(config['lockTimeout'].toString());
        }
      } catch (e) {
        LoggerUtil.error(TAG, 'Invalid unlockDuration or lockTimeout value, using default', e);
      }

      // Cancel existing timer if any
      _timer?.cancel();

      // Create a periodic timer that will show the alert
      _timer = Timer.periodic(Duration(minutes: 1), (timer) async {
        try {
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

            LoggerUtil.debug(TAG, 'Current minute: $currentMinute, Cycle start: $cycleStartMinute, Lock start: $lockStartMinute, Lock end: $lockEndMinute');

            // Check if current time falls within the lock period
            if (currentMinute >= lockStartMinute &&
                currentMinute < lockEndMinute &&
                lockEndMinute <= 60) {
              // Fire and forget operation - don't await the result
              _showSystemAlert('Lock Alert',
                      'Time to lock the device for $lockTimeout minutes!')
                  .catchError((error) {
                LoggerUtil.error(TAG, 'Error in showing system alert', error);
              });
            } else {
              await _closeSystemAlert();
            }
          } else {
            LoggerUtil.error(TAG, 'Cannot show alert - overlay permission not granted');
          }
        } catch (e, stackTrace) {
          LoggerUtil.error(TAG, 'Error in periodic timer', e, stackTrace);
        }
      });

      LoggerUtil.debug(TAG, 'Background service started with unlockDuration: $unlockDuration minutes and lockTimeout: $lockTimeout minutes');
      await startAndroidService();
    } catch (e, stackTrace) {
      LoggerUtil.error(TAG, 'Error starting background service', e, stackTrace);
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
    } catch (e, stackTrace) {
      LoggerUtil.error(TAG, 'Error checking overlay permission', e, stackTrace);
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
    } on PlatformException catch (e, stackTrace) {
      LoggerUtil.error(TAG, 'Failed to show system alert', e, stackTrace);
      if (e.code == 'PERMISSION_DENIED') {
        await _ensureOverlayPermission();
      }
      rethrow; // Rethrow to allow retry in startService
    } catch (e, stackTrace) {
      LoggerUtil.error(TAG, 'Unexpected error showing system alert', e, stackTrace);
      rethrow; // Rethrow to allow retry in startService
    }
  }

  static Future<void> _closeSystemAlert() async {
    try {
      await platform.invokeMethod('closeSystemAlert');
    } catch (e, stackTrace) {
      LoggerUtil.error(TAG, 'Error closing system alert', e, stackTrace);
    }
  }

  static void dispose() {
    _timer?.cancel();
    _timer = null;
  }

  static Future<void> startAndroidService() async {
    try {
      await platform.invokeMethod('startAndroidService');
    } catch (e, stackTrace) {
      LoggerUtil.error(TAG, 'Error starting Android background service', e, stackTrace);
    }
  }
}
