import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../configuration.dart';
import '../services/background_service.dart';

class ConfigurationScreen extends StatefulWidget {
  @override
  _ConfigurationScreenState createState() => _ConfigurationScreenState();
}

class _ConfigurationScreenState extends State<ConfigurationScreen> {
  static const platform = MethodChannel('com.example.flutter_time_lock/system');
  Map<String, dynamic> config = Configuration.config;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _checkOverlayPermission();
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

  Future<void> _saveConfig() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      await Configuration.saveConfig(config);
      await BackgroundService.startService(config);
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
