import 'package:flutter/material.dart';
import 'configuration.dart';
import 'services/background_service.dart';
import 'screens/main_screen.dart';
import 'utils/logger.dart';
import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    LoggerUtil.debug('Main', 'Loading configuration');
    await Configuration.loadConfig();

    LoggerUtil.debug('Main', 'Initializing background service');
    await BackgroundService.initialize();

    LoggerUtil.debug('Main', 'Starting background service');
    await BackgroundService.startService(Configuration.config);

    // Request necessary permissions
    const platform = MethodChannel('com.example.flutter_time_lock/system');

    // Request overlay permission if not granted
    bool hasOverlayPermission =
        await platform.invokeMethod('checkOverlayPermission');
    if (!hasOverlayPermission) {
      await platform.invokeMethod('requestOverlayPermission');
    }

    // Request kill background processes permission if not granted
    bool hasKillPermission =
        await platform.invokeMethod('checkKillBackgroundProcessesPermission');
    if (!hasKillPermission) {
      await platform.invokeMethod('requestKillBackgroundProcessesPermission');
    }

    // Request WiFi control permission if not granted
    bool hasWifiPermission = await platform.invokeMethod('checkWifiPermission');
    if (!hasWifiPermission) {
      await platform.invokeMethod('requestWifiPermission');
    }
  } catch (e, stackTrace) {
    LoggerUtil.error('Main', 'Error during initialization', e, stackTrace);
  }

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Time Lock',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MainScreen(),
    );
  }
}
