import 'package:flutter_background/flutter_background.dart';
import 'dart:async';
import 'package:flutter/services.dart';

class BackgroundService {
  static const platform = MethodChannel('com.example.flutter_time_lock/system');

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
      print('Failed to initialize FlutterBackground');
    }
  }

  static Future<void> startService(Map<String, dynamic> config) async {
    try {
      bool hasPermissions = await FlutterBackground.hasPermissions;
      if (!hasPermissions) {
        print('Background execution permission not granted');
        return;
      }

      bool enabled = await FlutterBackground.enableBackgroundExecution();
      if (!enabled) {
        print('Failed to enable background execution');
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
        print('Invalid interval value, using default: $e');
      }

      // Convert minutes to seconds
      int intervalSeconds = intervalMinutes * 5;

      Timer.periodic(Duration(seconds: intervalSeconds), (timer) {
        _showSystemAlert('Lock Alert', 'Time to lock the device!');
      });
    } catch (e) {
      print('Error starting background service: $e');
    }
  }

  static Future<void> _showSystemAlert(String title, String message) async {
    try {
      await platform.invokeMethod(
          'showSystemAlert', {'title': title, 'message': message});
    } on PlatformException catch (e) {
      print("Failed to show system alert: ${e.message}");
      // If permission is denied, request it again
      if (e.code == 'PERMISSION_DENIED') {
        await _checkOverlayPermission();
      }
    }
  }

  static Future<void> _checkOverlayPermission() async {
    try {
      bool hasPermission =
          await platform.invokeMethod('checkOverlayPermission');
      if (!hasPermission) {
        await platform.invokeMethod('requestOverlayPermission');
      }
    } catch (e) {
      print('Error checking overlay permission: $e');
    }
  }
}
