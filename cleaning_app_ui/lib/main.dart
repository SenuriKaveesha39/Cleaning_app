import 'package:flutter/material.dart';
import 'screens/clock_history_screen.dart';
import 'screens/login_screen.dart';
import 'screens/admin_dashboard.dart';
import 'screens/cleaner_tracker.dart';

void main() {
  runApp(MaterialApp(
    home: LoginScreen(),
    routes: {
      '/adminDashboard': (context) => AdminDashboard(token: ''), 
      '/cleanerTracker': (context) => CleanerTimeTracker(),
      '/clockHistory': (context) => ClockHistoryScreen(),
    },
  ));
}
