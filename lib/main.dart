import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:flutter_background/flutter_background.dart';
import 'package:flutter/services.dart';

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
      home: MainScreen(),
    );
  }
}

class MainScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Main Screen'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ConfigurationScreen()),
            );
          },
          child: Text('Go to Configuration'),
        ),
      ),
    );
  }
}

class ConfigurationScreen extends StatefulWidget {
  @override
  _ConfigurationScreenState createState() => _ConfigurationScreenState();
}

class _ConfigurationScreenState extends State<ConfigurationScreen> {
  static const platform = MethodChannel('com.example.flutter_time_lock/system');
  Map<String, dynamic> config = {
    'childPin': '',
    'adultPin': '',
    'lockTime': '',
    'lockInterval': '',
    'timerUnit': 'seconds'
  };

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _checkAndCreateConfigFile();
    _checkOverlayPermission();
    _startBackgroundService();
  }

  Future<void> _checkOverlayPermission() async {
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

  Future<void> _checkAndCreateConfigFile() async {
    final directory = await Directory.systemTemp.createTemp();
    final path = '${directory.path}/config.json';
    final file = File(path);

    try {
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
          'lockInterval': '2',
          'timerUnit': 'seconds'
        };
        await file.writeAsString(jsonEncode(defaultConfig));
        setState(() {
          config = defaultConfig;
        });
      }
    } catch (e) {
      print('Error reading configuration file: $e');
      final defaultConfig = {
        'childPin': '1234',
        'adultPin': '5678',
        'lockTime': '1',
        'lockInterval': '2',
        'timerUnit': 'seconds'
      };
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
      int intervalSeconds = intervalMinutes * 5;

      Timer.periodic(Duration(seconds: intervalSeconds), (timer) {
        _showLockDialog();
      });
    } catch (e) {
      print('Error starting background service: $e');
    }
  }

  Future<void> _showSystemAlert() async {
    try {
      await platform.invokeMethod('showSystemAlert',
          {'title': 'Lock Alert', 'message': 'Time to lock the device!'});
    } on PlatformException catch (e) {
      print("Failed to show system alert: ${e.message}");
      // If permission is denied, request it again
      if (e.code == 'PERMISSION_DENIED') {
        await _checkOverlayPermission();
      }
    }
  }

  void _showLockDialog() {
    _showSystemAlert(); // Always use system alert instead of Flutter dialog
  }

  Future<void> _saveConfig() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final directory = await Directory.systemTemp.createTemp();
      final path = '${directory.path}/config.json';
      final file = File(path);
      await file.writeAsString(jsonEncode(config));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Configuration saved')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Flutter Time Lock'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              TextFormField(
                initialValue: config['childPin'],
                decoration: InputDecoration(labelText: 'Child Pin'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a child pin';
                  }
                  return null;
                },
                onSaved: (value) {
                  config['childPin'] = value!;
                },
              ),
              TextFormField(
                initialValue: config['adultPin'],
                decoration: InputDecoration(labelText: 'Adult Pin'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an adult pin';
                  }
                  return null;
                },
                onSaved: (value) {
                  config['adultPin'] = value!;
                },
              ),
              TextFormField(
                initialValue: config['lockTime'],
                decoration: InputDecoration(labelText: 'Lock Time'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a lock time';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
                onSaved: (value) {
                  config['lockTime'] = value!;
                },
              ),
              TextFormField(
                initialValue: config['lockInterval'],
                decoration: InputDecoration(labelText: 'Lock Interval'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a lock interval';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
                onSaved: (value) {
                  config['lockInterval'] = value!;
                },
              ),
              DropdownButtonFormField<String>(
                value: config['timerUnit'],
                decoration: InputDecoration(labelText: 'Timer Unit'),
                items: ['seconds', 'minutes']
                    .map((unit) => DropdownMenuItem(
                          value: unit,
                          child: Text(unit),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    config['timerUnit'] = value!;
                  });
                },
                onSaved: (value) {
                  config['timerUnit'] = value!;
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveConfig,
                child: Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
