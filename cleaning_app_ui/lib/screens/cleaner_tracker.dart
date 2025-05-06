import 'package:flutter/material.dart';

class CleanerTimeTracker extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Cleaner Tracker')),
      body: Center(
        child: Text('Welcome Cleaner! Start your time tracking.'),
      ),
    );
  }
}
