import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_services.dart';

class CleanerTimeTracker extends StatefulWidget {
  @override
  _CleanerTimeTrackerState createState() => _CleanerTimeTrackerState();
}

class _CleanerTimeTrackerState extends State<CleanerTimeTracker> {
  bool isClockedIn = false;
  String statusMessage = 'Checking status...';

  @override
  void initState() {
    super.initState();
    fetchClockStatus();
  }

  Future<void> fetchClockStatus() async {
    final status = await ApiService.getTodayClockStatus();
    setState(() {
      isClockedIn = status['clockIn'] != null && status['clockOut'] == null;
      statusMessage = isClockedIn
          ? 'You are clocked in since ${status['clockIn']}'
          : (status['clockOut'] != null
              ? 'Clocked out at ${status['clockOut']}'
              : 'You have not clocked in yet.');
    });
  }

  Future<void> toggleClock() async {
    final success = await ApiService.toggleClockInOut(isClockedIn);
    if (success) {
      await fetchClockStatus();
    } else {
      setState(() {
        statusMessage = "Failed to update clock status.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Cleaner Time Tracker')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(statusMessage, style: TextStyle(fontSize: 18)),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: toggleClock,
              child: Text(isClockedIn ? 'Clock Out' : 'Clock In'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isClockedIn ? Colors.red : Colors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
