import 'dart:async';
import 'dart:ui';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter/services.dart';
import '../utils/logger.dart';
import '../configuration.dart';

class BackgroundService {
  static const platform = MethodChannel('com.example.flutter_time_lock/system');
  static const String TAG = "BackgroundService";
  static FlutterBackgroundService? _instance;

  static Future<void> initialize() async {
    try {
      _instance = FlutterBackgroundService();

      // Configure background service
      await _instance!.configure(
        androidConfiguration: AndroidConfiguration(
          onStart: onStart,
          autoStart: true,
          isForegroundMode: true,
          notificationChannelId: 'flutter_time_lock_channel',
          initialNotificationTitle: 'Flutter Time Lock',
          initialNotificationContent: 'Running',
          foregroundServiceNotificationId: 1,
        ),
        iosConfiguration: IosConfiguration(),
      );

      LoggerUtil.debug(TAG, 'Background service initialized');
    } catch (e, stackTrace) {
      LoggerUtil.error(
          TAG, 'Error initializing background service', e, stackTrace);
    }
  }

  @pragma('vm:entry-point')
  static Future<void> onStart(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();
    LoggerUtil.debug(TAG, 'Background service started');

    // Initialize method channel in background isolate
    const methodChannel = MethodChannel('com.example.flutter_time_lock/system');

    // Load initial configuration
    await Configuration.loadConfig();
    Map<String, dynamic> config = Configuration.config;

    Timer? timer;

    void startTimer() {
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
        LoggerUtil.error(TAG,
            'Invalid unlockDuration or lockTimeout value, using default', e);
      }

      // Create a periodic timer that will show the alert
      timer = Timer.periodic(const Duration(minutes: 1), (timer) async {
        try {
          // Ensure we have overlay permission before showing alert
          bool hasPermission =
              await BackgroundService._ensureOverlayPermission(methodChannel);
          if (hasPermission) {
            DateTime now = DateTime.now();
            int currentMinute = now.minute;

            // Calculate how many complete cycles have passed in this hour
            int completedCycles =
                currentMinute ~/ (unlockDuration + lockTimeout);

            // Calculate the start of the current cycle
            int cycleStartMinute =
                completedCycles * (unlockDuration + lockTimeout);

            // Calculate lock period start and end for current cycle
            int lockStartMinute = cycleStartMinute + unlockDuration;
            int lockEndMinute = lockStartMinute + lockTimeout;

            LoggerUtil.debug(TAG,
                'Current minute: $currentMinute, Cycle start: $cycleStartMinute, Lock start: $lockStartMinute, Lock end: $lockEndMinute');

            // Check if current time falls within the lock period
            if (currentMinute >= lockStartMinute &&
                currentMinute < lockEndMinute &&
                lockEndMinute <= 60) {
              LoggerUtil.debug(TAG, 'Device locked for $lockTimeout minutes');
              _showSystemAlert(methodChannel, 'Lock Alert',
                      'Time to lock the device for $lockTimeout minutes!')
                  .catchError((error) {
                LoggerUtil.error(TAG, 'Error in showing system alert', error);
              });
            } else {
              LoggerUtil.debug(
                  TAG, 'Device unlocked for $unlockDuration minutes');
              await _closeSystemAlert(methodChannel);
            }
          } else {
            LoggerUtil.error(
                TAG, 'Cannot show alert - overlay permission not granted');
          }
        } catch (e, stackTrace) {
          LoggerUtil.error(TAG, 'Error in periodic timer', e, stackTrace);
        }
      });
    }

    // Listen for configuration updates
    service.on('updateConfig').listen((event) async {
      if (event != null) {
        config = Map<String, dynamic>.from(event);
        timer?.cancel();
        startTimer();
        LoggerUtil.debug(TAG, 'Configuration updated: $config');
      }
    });

    // Start initial timer
    startTimer();
  }

  static Future<void> startService(Map<String, dynamic> config) async {
    try {
      if (_instance != null) {
        await _instance!.startService();
        _instance!.invoke('updateConfig', config);
        LoggerUtil.debug(
            TAG, 'Background service started with config: $config');
      }
    } catch (e, stackTrace) {
      LoggerUtil.error(TAG, 'Error starting background service', e, stackTrace);
    }
  }

  static Future<void> resetService(Map<String, dynamic> config) async {
    try {
      if (_instance != null) {
        _instance!.invoke('updateConfig', config);
        LoggerUtil.debug(TAG, 'Background service reset with config: $config');
      }
    } catch (e, stackTrace) {
      LoggerUtil.error(
          TAG, 'Error resetting background service', e, stackTrace);
    }
  }

  static Future<bool> _ensureOverlayPermission(MethodChannel channel) async {
    try {
      bool hasPermission = await channel.invokeMethod('checkOverlayPermission');
      if (!hasPermission) {
        await channel.invokeMethod('requestOverlayPermission');
        hasPermission = await channel.invokeMethod('checkOverlayPermission');
      }
      return hasPermission;
    } catch (e, stackTrace) {
      LoggerUtil.error(TAG, 'Error checking overlay permission', e, stackTrace);
      return false;
    }
  }

  static Future<void> _showSystemAlert(
      MethodChannel channel, String title, String message) async {
    try {
      final bool? result = await channel.invokeMethod(
          'showSystemAlert', {'title': title, 'message': message});
      if (result == false) {
        throw PlatformException(
            code: 'ALERT_DISMISSED',
            message: 'Alert was dismissed or failed to show');
      }
    } catch (e, stackTrace) {
      LoggerUtil.error(TAG, 'Failed to show system alert', e, stackTrace);
      if (e is PlatformException && e.code == 'PERMISSION_DENIED') {
        await _ensureOverlayPermission(channel);
      }
      rethrow;
    }
  }

  static Future<void> _closeSystemAlert(MethodChannel channel) async {
    try {
      await channel.invokeMethod('closeSystemAlert');
    } catch (e, stackTrace) {
      LoggerUtil.error(TAG, 'Error closing system alert', e, stackTrace);
    }
  }

  static void dispose() {
    _instance?.invoke('stopService');
    LoggerUtil.debug(TAG, 'Background service disposed');
  }
}
