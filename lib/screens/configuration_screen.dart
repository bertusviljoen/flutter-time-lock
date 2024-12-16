import 'package:flutter/material.dart';
import '../configuration.dart';
import '../services/background_service.dart';
import '../utils/logger.dart';

class ConfigurationScreen extends StatefulWidget {
  @override
  _ConfigurationScreenState createState() => _ConfigurationScreenState();
}

class _ConfigurationScreenState extends State<ConfigurationScreen> {
  Map<String, dynamic> config = Configuration.config;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
  }

  Future<void> _saveConfig() async {
    try {
      if (_formKey.currentState!.validate()) {
        _formKey.currentState!.save();
        LoggerUtil.debug(
            'ConfigurationScreen', 'Saving configuration: $config');
        await Configuration.saveConfig(config);
        LoggerUtil.debug('ConfigurationScreen',
            'Starting background service with new config');
        await BackgroundService.startService(config);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Configuration saved')),
        );
      }
    } catch (e, stackTrace) {
      LoggerUtil.error(
          'ConfigurationScreen', 'Error saving configuration', e, stackTrace);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving configuration')),
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
                initialValue: config['unlockDuration'].toString(),
                decoration:
                    InputDecoration(labelText: 'Unlock Duration (minutes)'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an unlock duration';
                  }
                  final intValue = int.tryParse(value);
                  if (intValue == null || intValue < 1 || intValue > 60) {
                    return 'Please enter a valid number between 1 and 60';
                  }
                  return null;
                },
                onSaved: (value) {
                  config['unlockDuration'] = int.parse(value!);
                },
              ),
              TextFormField(
                initialValue: config['lockTimeout'].toString(),
                decoration:
                    InputDecoration(labelText: 'Lock Timeout (minutes)'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a lock timeout';
                  }
                  final intValue = int.tryParse(value);
                  if (intValue == null || intValue < 1 || intValue > 60) {
                    return 'Please enter a valid number between 1 and 60';
                  }
                  return null;
                },
                onSaved: (value) {
                  config['lockTimeout'] = int.parse(value!);
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
