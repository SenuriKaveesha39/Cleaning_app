import 'package:flutter/material.dart';
import 'register_cleaner_page.dart';

class AdminDashboard extends StatelessWidget {
  final String token;

  AdminDashboard({required this.token}); // Only one token

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Admin Dashboard")),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RegisterCleanerPage(adminToken: token),
              ),
            );
          },
          child: Text("Register New Cleaner"),
        ),
      ),
    );
  }
}
