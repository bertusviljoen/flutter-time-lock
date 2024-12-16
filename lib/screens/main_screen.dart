import 'package:flutter/material.dart';
import 'configuration_screen.dart';

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
