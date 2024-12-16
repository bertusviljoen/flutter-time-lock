import 'dart:async';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import '../utils/logger.dart';
import '../configuration.dart';

class BackgroundService {
  static const String TAG = "BackgroundService";
  static BackgroundService? _instance;

  static Future<void> initialize() async {
    try {
      _instance = BackgroundService();

      FlutterBackgroundService.initialize(onStart);

      LoggerUtil.debug(TAG, 'Background service initialized');
    } catch (e, stackTrace) {
      LoggerUtil.error(
          TAG, 'Error initializing background service', e, stackTrace);
    }
  }

  @pragma('vm:entry-point')
  static Future<void> onStart(ServiceInstance service) async {
    LoggerUtil.debug(TAG, 'Background service started');

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
            // Show system alert logic here
          } else {
            LoggerUtil.debug(
                TAG, 'Device unlocked for $unlockDuration minutes');
            // Close system alert logic here
          }
        } catch (e, stackTrace) {
          LoggerUtil.error(TAG, 'Error in periodic timer', e, stackTrace);
        }
      });
    }

    // Listen for configuration updates
    service.on('updateConfig').listen((event) {
      config = Map<String, dynamic>.from(event!);
      timer?.cancel();
      startTimer();
      LoggerUtil.debug(TAG, 'Configuration updated: $config');
    });

    // Start initial timer
    startTimer();
  }

  static Future<void> startService(Map<String, dynamic> config) async {
    try {
      if (_instance != null) {
        FlutterBackgroundService().sendData({'action': 'updateConfig', 'config': config});
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
        FlutterBackgroundService().sendData({'action': 'updateConfig', 'config': config});
        LoggerUtil.debug(TAG, 'Background service reset with config: $config');
      }
    } catch (e, stackTrace) {
      LoggerUtil.error(
          TAG, 'Error resetting background service', e, stackTrace);
    }
  }

  static void dispose() {
    FlutterBackgroundService().sendData({'action': 'stopService'});
    LoggerUtil.debug(TAG, 'Background service disposed');
  }
}
