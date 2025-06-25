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
    _refreshData();
  }

  Future<void> _refreshData() async {
    setState(() {
      _historyFuture = ApiService.getClockHistory();
    });
  }

  String _formatDate(String dateStr) {
    final date = DateTime.parse(dateStr);
    return DateFormat('EEE, MMM d').format(date);
  }

  String _formatTime(String? time) {
    if (time == null) return "--:--";
    final dt = DateTime.parse(time).toLocal();
    return DateFormat('HH:mm').format(dt);
  }

  String _getDuration(String? inTime, String? outTime) {
    if (inTime == null) return "-";
    final start = DateTime.parse(inTime);
    final end = outTime != null ? DateTime.parse(outTime) : DateTime.now();
    final duration = end.difference(start);
    return "${duration.inHours}h ${duration.inMinutes.remainder(60)}m";
  }

  Widget _buildSessionItem(Map<String, dynamic> session) {
    final isComplete = session['clockOut'] != null;
    return ListTile(
      contentPadding: EdgeInsets.symmetric(vertical: 8),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isComplete ? Colors.green[100] : Colors.orange[100],
          shape: BoxShape.circle,
        ),
        child: Icon(
          isComplete ? Icons.check_circle : Icons.access_time,
          color: isComplete ? Colors.green : Colors.orange,
        ),
      ),
      title: Text(
        "${_formatTime(session['clockIn'])} - ${_formatTime(session['clockOut'])}",
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: Colors.grey[800],
        ),
      ),
      subtitle: Text(
        _getDuration(session['clockIn'], session['clockOut']),
        style: TextStyle(
          color: isComplete ? Colors.grey[600] : Colors.orange,
          fontWeight: isComplete ? FontWeight.normal : FontWeight.bold,
        ),
      ),
      trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> record) {
    final date = record['date'] ?? 'Unknown Date';
    final sessions = (record['sessions'] as List<dynamic>?) ?? [];
    final totalDuration = sessions.fold<Duration>(Duration.zero, (prev, session) {
      final inTime = session['clockIn'];
      final outTime = session['clockOut'];
      if (inTime == null) return prev;
      final start = DateTime.parse(inTime);
      final end = outTime != null ? DateTime.parse(outTime) : DateTime.now();
      return prev + end.difference(start);
    });

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ExpansionTile(
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            shape: BoxShape.circle,
          ),
          child: Text(
            DateFormat('d').format(DateTime.parse(date)),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue[800],
            ),
          ),
        ),
        title: Text(
          _formatDate(date),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        subtitle: Text(
          "Total: ${totalDuration.inHours}h ${totalDuration.inMinutes.remainder(60)}m",
          style: TextStyle(color: Colors.grey[600]),
        ),
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: ListView.separated(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: sessions.length,
              separatorBuilder: (_, __) => Divider(height: 1),
              itemBuilder: (context, index) => _buildSessionItem(sessions[index]),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Work History",
            style: TextStyle(fontWeight: FontWeight.w600)),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _refreshData,
            tooltip: "Refresh History",
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _historyFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator.adaptive(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Colors.red),
                    SizedBox(height: 16),
                    Text("Failed to load history",
                        style: Theme.of(context).textTheme.titleMedium),
                    SizedBox(height: 8),
                    ElevatedButton.icon(
                      icon: Icon(Icons.refresh),
                      label: Text("Try Again"),
                      onPressed: _refreshData,
                    ),
                  ],
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.history_toggle_off, size: 48, color: Colors.grey),
                    SizedBox(height: 16),
                    Text("No clock history found",
                        style: Theme.of(context).textTheme.titleMedium),
                    Text("Your shifts will appear here once recorded",
                        style: TextStyle(color: Colors.grey)),
                  ],
                ),
              );
            }

            final history = snapshot.data!;
            return ListView.builder(
              padding: EdgeInsets.only(top: 16, bottom: 24),
              itemCount: history.length,
              itemBuilder: (context, index) => _buildHistoryCard(history[index]),
            );
          },
        ),
      ),
    );
  }
}
