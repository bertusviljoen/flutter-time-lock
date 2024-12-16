import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
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
    final file = await _localFile;
    await file.writeAsString(jsonEncode(_config));
  }
}
