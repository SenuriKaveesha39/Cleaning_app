import 'package:flutter/material.dart';
import '../services/api_services.dart';
import 'package:intl/intl.dart';

class ClockHistoryScreen extends StatefulWidget {
  @override
  _ClockHistoryScreenState createState() => _ClockHistoryScreenState();
}

class _ClockHistoryScreenState extends State<ClockHistoryScreen> {
  late Future<List<Map<String, dynamic>>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = ApiService.getClockHistory();
  }

  String _formatTime(String? time) {
    if (time == null) return "-";
    final dt = DateTime.parse(time).toLocal();
    return DateFormat('hh:mm a').format(dt);
  }

  String _getDuration(String? inTime, String? outTime) {
    if (inTime == null) return "-";
    if (outTime == null) return "In Progress";
    
    final start = DateTime.parse(inTime);
    final end = DateTime.parse(outTime);
    final duration = end.difference(start);
    return "${duration.inHours}h ${duration.inMinutes.remainder(60)}m";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Clock History")),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Failed to load history"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text("No records found"));
          }

          final history = snapshot.data!;

          return ListView.builder(
            itemCount: history.length,
            itemBuilder: (context, index) {
              final record = history[index];
              final date = record['date'] ?? 'Unknown Date';
              final sessions = (record['sessions'] as List<dynamic>?) ?? [];

              return Card(
                margin: EdgeInsets.all(8),
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Date: $date", 
                          style: TextStyle(
                              fontSize: 16, 
                              fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      ...sessions.map((session) {
                        final clockIn = session['clockIn'];
                        final clockOut = session['clockOut'];
                        return Padding(
                          padding: EdgeInsets.only(bottom: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("→ Clock In: ${_formatTime(clockIn)}"),
                              Text("← Clock Out: ${_formatTime(clockOut)}"),
                              Text("⏱ Worked: ${_getDuration(clockIn, clockOut)}"),
                              Divider(),
                            ],
                          ),
                        );
                      }).toList(),
                      if (sessions.isEmpty)
                        Text("No clock sessions recorded",
                            style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
