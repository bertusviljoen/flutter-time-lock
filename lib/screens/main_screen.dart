import 'package:flutter/material.dart';
import 'configuration_screen.dart';
import 'permissions_screen.dart';
import '../utils/logger.dart';

class MainScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Main Screen'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: () {
                try {
                  LoggerUtil.debug('MainScreen', 'Navigating to ConfigurationScreen');
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ConfigurationScreen()),
                  );
                } catch (e, stackTrace) {
                  LoggerUtil.error('MainScreen', 'Error navigating to ConfigurationScreen', e, stackTrace);
                }
              },
              child: Text('Go to Configuration'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                try {
                  LoggerUtil.debug('MainScreen', 'Navigating to PermissionsScreen');
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => PermissionsScreen()),
                  );
                } catch (e, stackTrace) {
                  LoggerUtil.error('MainScreen', 'Error navigating to PermissionsScreen', e, stackTrace);
                }
              },
              child: Text('Go to Permissions'),
            ),
          ],
        ),
      ),
    );
  }
}
