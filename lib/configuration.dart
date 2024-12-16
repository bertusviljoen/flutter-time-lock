import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';

class Configuration {
  static const String _configFileName = 'config.json';
  static Map<String, dynamic> _config = {
    'adultPin': '',
    'unlockDuration': 20,
    'lockTimeout': 10
  };

  static Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  static Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/$_configFileName');
  }

  static Future<void> loadConfig() async {
    try {
      final file = await _localFile;
      if (await file.exists()) {
        final contents = await file.readAsString();
        _config = jsonDecode(contents);
      } else {
        final defaultConfig = {
          'adultPin': '5678',
          'unlockDuration': 20,
          'lockTimeout': 10
        };
        await file.writeAsString(jsonEncode(defaultConfig));
        _config = defaultConfig;
      }
    } catch (e) {
      print('Error reading configuration file: $e');
      final defaultConfig = {
        'adultPin': '5678',
        'unlockDuration': 20,
        'lockTimeout': 10
      };
      _config = defaultConfig;
    }
  }

  static Map<String, dynamic> get config => _config;

  static Future<void> saveConfig(Map<String, dynamic> newConfig) async {
    if (newConfig['unlockDuration'] is! int || newConfig['unlockDuration'] < 5 || newConfig['unlockDuration'] > 60) {
      throw Exception('Invalid unlockDuration value');
    }
    if (newConfig['lockTimeout'] is! int || newConfig['lockTimeout'] < 1 || newConfig['lockTimeout'] > 60) {
      throw Exception('Invalid lockTimeout value');
    }
    _config = newConfig;
    final file = await _localFile;
    await file.writeAsString(jsonEncode(_config));
  }
}
