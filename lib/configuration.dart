import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';

class Configuration {
  static const String _configFileName = 'config.json';
  static Map<String, dynamic> _config = {
    'childPin': '',
    'adultPin': '',
    'lockTime': '',
    'lockInterval': '',
    'timerUnit': 'seconds'
  };

  static Future<void> loadConfig() async {
    final directory = await Directory.systemTemp.createTemp();
    final path = '${directory.path}/$_configFileName';
    final file = File(path);

    try {
      if (await file.exists()) {
        final contents = await file.readAsString();
        _config = jsonDecode(contents);
      } else {
        final defaultConfig = {
          'childPin': '1234',
          'adultPin': '5678',
          'lockTime': '1',
          'lockInterval': '2',
          'timerUnit': 'seconds'
        };
        await file.writeAsString(jsonEncode(defaultConfig));
        _config = defaultConfig;
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
      _config = defaultConfig;
    }
  }

  static Map<String, dynamic> get config => _config;

  static Future<void> saveConfig(Map<String, dynamic> newConfig) async {
    _config = newConfig;
    final directory = await Directory.systemTemp.createTemp();
    final path = '${directory.path}/$_configFileName';
    final file = File(path);
    await file.writeAsString(jsonEncode(_config));
  }
}
