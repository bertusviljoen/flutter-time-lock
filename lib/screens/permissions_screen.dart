import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PermissionsScreen extends StatefulWidget {
  @override
  _PermissionsScreenState createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  static const platform = MethodChannel('com.example.flutter_time_lock/system');
  bool _overlayPermission = false;
  bool _wifiPermission = false;

  @override
  void initState() {
    super.initState();
    _checkOverlayPermission();
    _checkWifiPermission();
  }

  Future<void> _checkOverlayPermission() async {
    try {
      bool hasPermission =
          await platform.invokeMethod('checkOverlayPermission');
      setState(() {
        _overlayPermission = hasPermission;
      });
    } catch (e) {
      print('Error checking overlay permission: $e');
    }
  }

  Future<void> _checkWifiPermission() async {
    try {
      bool hasPermission = await platform.invokeMethod('checkWifiPermission');
      setState(() {
        _wifiPermission = hasPermission;
      });
    } catch (e) {
      print('Error checking wifi permission: $e');
    }
  }

  Future<void> _requestOverlayPermission() async {
    try {
      await platform.invokeMethod('requestOverlayPermission');
      _checkOverlayPermission();
    } catch (e) {
      print('Error requesting overlay permission: $e');
    }
  }

  Future<void> _requestWifiPermission() async {
    try {
      await platform.invokeMethod('requestWifiPermission');
      _checkWifiPermission();
    } catch (e) {
      print('Error requesting wifi permission: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Permissions Screen'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text('Overlay Permission'),
                Switch(
                  value: _overlayPermission,
                  onChanged: (value) {
                    if (!value) {
                      _requestOverlayPermission();
                    }
                  },
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text('WiFi Permission'),
                Switch(
                  value: _wifiPermission,
                  onChanged: (value) {
                    if (!value) {
                      _requestWifiPermission();
                    }
                  },
                ),
              ],
            ),
            ElevatedButton(
              onPressed: _requestOverlayPermission,
              child: Text('Request Overlay Permission'),
            ),
            ElevatedButton(
              onPressed: _requestWifiPermission,
              child: Text('Request WiFi Permission'),
            ),
          ],
        ),
      ),
    );
  }
}
