import 'package:flutter/material.dart';
import 'configuration_screen.dart';
import 'permissions_screen.dart';

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
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ConfigurationScreen()),
                );
              },
              child: Text('Go to Configuration'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PermissionsScreen()),
                );
              },
              child: Text('Go to Permissions'),
            ),
          ],
        ),
      ),
    );
  }
}
