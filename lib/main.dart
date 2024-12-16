import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:flutter_background/flutter_background.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
      home: ConfigurationScreen(),
    );
  }
}

class ConfigurationScreen extends StatefulWidget {
  @override
  _ConfigurationScreenState createState() => _ConfigurationScreenState();
}

class _ConfigurationScreenState extends State<ConfigurationScreen> {
  Map<String, dynamic> config = {
    'childPin': '',
    'adultPin': '',
    'lockTime': '',
    'lockInterval': ''
  };

  @override
  void initState() {
    super.initState();
    _checkAndCreateConfigFile();
    _startBackgroundService();
  }

  Future<void> _checkAndCreateConfigFile() async {
    final directory = await Directory.systemTemp.createTemp();
    final path = '${directory.path}/config.json';
    final file = File(path);

    if (await file.exists()) {
      final contents = await file.readAsString();
      setState(() {
        config = jsonDecode(contents);
      });
    } else {
      final defaultConfig = {
        'childPin': '1234',
        'adultPin': '5678',
        'lockTime': '1',
        'lockInterval': '2'
      };
      await file.writeAsString(jsonEncode(defaultConfig));
      setState(() {
        config = defaultConfig;
      });
    }
  }

  Future<void> _startBackgroundService() async {
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
      int intervalSeconds = intervalMinutes * 60;

      Timer.periodic(Duration(seconds: intervalSeconds), (timer) {
        _showLockDialog();
      });
    } catch (e) {
      print('Error starting background service: $e');
    }
  }

  void _showLockDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Lock Alert'),
          content: Text('Time to lock the device!'),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Flutter Time Lock'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('Child Pin: ${config['childPin']}'),
            Text('Adult Pin: ${config['adultPin']}'),
            Text('Lock Time: ${config['lockTime']} mins'),
            Text('Lock Interval: ${config['lockInterval']} mins'),
          ],
        ),
      ),
    );
  }
}
