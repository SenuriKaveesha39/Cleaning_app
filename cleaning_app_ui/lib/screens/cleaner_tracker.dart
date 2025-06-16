import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CleanerTimeTracker extends StatefulWidget {
  @override
  _CleanerTimeTrackerState createState() => _CleanerTimeTrackerState();
}

class _CleanerTimeTrackerState extends State<CleanerTimeTracker> {
  bool isClockedIn = false;
  DateTime? clockInTime;
  Timer? _timer;
  Duration shiftDuration = Duration.zero;
  String statusMessage = "";

  @override
  void initState() {
    super.initState();
    _loadSavedClockInTime();

    ApiService.getTodayClockStatus().then((data) {
      final clockIn = data['clockIn'];
      final clockOut = data['clockOut'];

      if (clockIn != null && clockOut == null) {
        setState(() {
          isClockedIn = true;
          clockInTime = DateTime.parse(clockIn);
          _startTimer();
        });
      }
    });
  }

  void _loadSavedClockInTime() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTime = prefs.getString('clockInTime');
    if (savedTime != null) {
      setState(() {
        isClockedIn = true;
        clockInTime = DateTime.parse(savedTime);
        _startTimer();
      });
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: 1), (_) {
      setState(() {
        if (clockInTime != null) {
          shiftDuration = DateTime.now().difference(clockInTime!);
        }
      });
    });
  }

  void _stopTimer() {
    _timer?.cancel();
  }

  void toggleClock() async {
    final prefs = await SharedPreferences.getInstance();
    final success = await ApiService.toggleClockInOut(isClockedIn);
    if (success) {
      setState(() {
        isClockedIn = !isClockedIn;
        if (isClockedIn) {
          clockInTime = DateTime.now();
          prefs.setString('clockInTime', clockInTime!.toIso8601String());
          _startTimer();
          statusMessage = "Clocked In";
        } else {
          prefs.remove('clockInTime');
          _stopTimer();
          shiftDuration = Duration.zero;
          statusMessage = "Clocked Out";
        }
      });
    } else {
      setState(() {
        statusMessage = "Clock action failed!";
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Cleaner Dashboard")),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              child: Text("Cleaner Menu", style: TextStyle(color: Colors.white, fontSize: 24)),
              decoration: BoxDecoration(color: Colors.blue),
            ),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text("Logout"),
              onTap: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text("Confirm Logout"),
                    content: Text("Are you sure you want to logout?"),
                    actions: [
                      TextButton(
                          child: Text("Cancel"),
                          onPressed: () => Navigator.pop(context, false)),
                      TextButton(
                          child: Text("Logout"),
                          onPressed: () => Navigator.pop(context, true)),
                    ],
                  ),
                );

                if (confirm ?? false) {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.clear();
                  Navigator.pushReplacementNamed(context, '/');
                }
              },
            ),
          ],
        ),
      ),
      body: Row(
        children: [
          Container(
            width: 200,
            color: Colors.blue[50],
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(Icons.access_time, size: 60, color: Colors.blue),
                SizedBox(height: 20),
                Text(
                  isClockedIn
                      ? "Working...\n${_formatDuration(shiftDuration)}"
                      : "Not Clocked In",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: toggleClock,
                  child: Text(isClockedIn ? "Clock Out" : "Clock In"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isClockedIn ? Colors.red : Colors.green,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                ),
                // 👇 ADD THIS BELOW
      SizedBox(height: 20),
      ElevatedButton.icon(
        onPressed: () {
          Navigator.pushNamed(context, '/clockHistory');
        },
        icon: Icon(Icons.history),
        label: Text("Clock History"),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueAccent,
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        ),
      )
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                statusMessage,
                style: TextStyle(fontSize: 24, color: Colors.black54),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    return "${twoDigits(duration.inHours)}:"
        "${twoDigits(duration.inMinutes.remainder(60))}:"
        "${twoDigits(duration.inSeconds.remainder(60))}";
  }
}
