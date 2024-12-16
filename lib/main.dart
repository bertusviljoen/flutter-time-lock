import 'package:flutter/material.dart';
import 'configuration.dart';
import 'services/background_service.dart';
import 'screens/main_screen.dart';
import 'utils/logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    LoggerUtil.debug('Main', 'Loading configuration');
    await Configuration.loadConfig();
    LoggerUtil.debug('Main', 'Initializing background service');
    await BackgroundService.initialize();
    LoggerUtil.debug('Main', 'Starting background service');
    await BackgroundService.startService(Configuration.config);
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
