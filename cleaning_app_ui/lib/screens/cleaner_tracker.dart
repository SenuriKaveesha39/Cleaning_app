import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

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
  String currentTime = '';
  List<Map<String, dynamic>> todaySessions = [];
  List<Map<String, dynamic>> weekHistory = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _startClock();
    _loadInitialData();
  }

  void _startClock() {
    _updateCurrentTime();
    _timer = Timer.periodic(Duration(seconds: 1), (_) => _updateCurrentTime());
  }

  void _updateCurrentTime() {
    setState(() {
      currentTime = DateFormat('HH:mm:ss').format(DateTime.now());
    });
  }

  Future<void> _loadInitialData() async {
    await _loadSavedClockInTime();
    await _fetchTodayStatus();
    await _fetchWeekHistory();
    setState(() => isLoading = false);
  }

  Future<void> _fetchTodayStatus() async {
    final status = await ApiService.getTodayClockStatus();
    setState(() {
      todaySessions = List<Map<String, dynamic>>.from(status['sessions'] ?? []);
      isClockedIn = todaySessions.isNotEmpty && 
                    todaySessions.last['clockOut'] == null;
    });
  }

  Future<void> _fetchWeekHistory() async {
    final history = await ApiService.getClockHistory();
    setState(() {
      weekHistory = history.take(7).toList();
    });
  }

  Future<void> _loadSavedClockInTime() async {
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

  Future<void> _toggleClock() async {
    setState(() => isLoading = true);
    try {
      final success = await ApiService.toggleClockInOut(isClockedIn);
      if (success) {
        final prefs = await SharedPreferences.getInstance();
        if (isClockedIn) {
          prefs.remove('clockInTime');
        } else {
          clockInTime = DateTime.now();
          prefs.setString('clockInTime', clockInTime!.toIso8601String());
        }
        await _fetchTodayStatus();
        _startTimer();
        _showStatusSnackbar(isClockedIn ? "Clocked Out" : "Clocked In");
      }
    } catch (e) {
      _showStatusSnackbar("Action failed: ${e.toString()}");
    }
    setState(() => isLoading = false);
  }

  void _showStatusSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: message.contains("failed") ? Colors.red : Colors.green,
      )
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Widget _buildTimeIndicator() {
    return Column(
      children: [
        Text(
          currentTime,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey[800],
          ),
        ),
        SizedBox(height: 8),
        LinearProgressIndicator(
          value: isClockedIn ? null : 0,
          backgroundColor: Colors.grey[200],
          color: Colors.blueAccent,
        ),
      ],
    );
  }

  Widget _buildSessionList() {
    if (todaySessions.isEmpty) {
      return Center(child: Text("No sessions today", style: TextStyle(color: Colors.grey)));
    }
    
    return ListView.separated(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: todaySessions.length,
      separatorBuilder: (_, __) => Divider(height: 1),
      itemBuilder: (context, index) {
        final session = todaySessions[index];
        return ListTile(
          leading: Icon(Icons.access_time, color: Colors.blueAccent),
          title: Text(
            "${_formatTime(session['clockIn'])} - ${_formatTime(session['clockOut'])}",
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          trailing: Text(_calculateDuration(session)),
        );
      },
    );
  }

  String _formatTime(String? time) {
    if (time == null) return "--:--";
    return DateFormat('HH:mm').format(DateTime.parse(time).toLocal());
  }

  String _calculateDuration(Map<String, dynamic> session) {
    final inTime = session['clockIn'];
    final outTime = session['clockOut'];
    if (inTime == null) return "-";
    
    final start = DateTime.parse(inTime);
    final end = outTime != null ? DateTime.parse(outTime) : DateTime.now();
    final duration = end.difference(start);
    
    return "${duration.inHours}h ${duration.inMinutes.remainder(60)}m";
  }

  Widget _buildWeeklySummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Text("Weekly Summary", style: Theme.of(context).textTheme.titleLarge),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 2.5,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
          ),
          itemCount: weekHistory.length,
          itemBuilder: (context, index) {
            final day = weekHistory[index];
            return _buildSummaryCard(day);
          },
        ),
      ],
    );
  }

  Widget _buildSummaryCard(Map<String, dynamic> day) {
    final sessions = List<Map<String, dynamic>>.from(day['sessions'] ?? []);
    final totalDuration = sessions.fold(Duration.zero, (prev, session) {
      final inTime = session['clockIn'];
      final outTime = session['clockOut'];
      if (inTime == null || outTime == null) return prev;
      return prev + DateTime.parse(outTime).difference(DateTime.parse(inTime));
    });

    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat('EEE, MMM d').format(DateTime.parse(day['date'])),
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              "${totalDuration.inHours}h ${totalDuration.inMinutes.remainder(60)}m",
              style: TextStyle(fontSize: 18, color: Colors.blueAccent),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Cleaner Dashboard"),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: isLoading ? null : _loadInitialData,
          ),
        ],
      ),
      drawer: _buildAppDrawer(),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadInitialData,
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Column(
                          children: [
                            _buildTimeIndicator(),
                            SizedBox(height: 24),
                            ElevatedButton.icon(
                              icon: Icon(
                                isClockedIn ? Icons.logout : Icons.login,
                                size: 28,
                              ),
                              label: Text(
                                isClockedIn ? "CLOCK OUT" : "CLOCK IN",
                                style: TextStyle(fontSize: 16),
                              ),
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: 20),
                                backgroundColor: isClockedIn ? Colors.redAccent : Colors.green,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: isLoading ? null : _toggleClock,
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 24),
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text("Today's Shifts", style: Theme.of(context).textTheme.titleLarge),
                            SizedBox(height: 16),
                            _buildSessionList(),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 24),
                    _buildWeeklySummary(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildAppDrawer() {
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            accountName: Text("Cleaner Name"),
            accountEmail: Text("cleaner@example.com"),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, size: 48),
            ),
            decoration: BoxDecoration(color: Colors.blueAccent),
          ),
          ListTile(
            leading: Icon(Icons.history),
            title: Text("Clock History"),
            onTap: () => Navigator.pushNamed(context, '/clockHistory'),
          ),
          ListTile(
            leading: Icon(Icons.settings),
            title: Text("Settings"),
            onTap: () {},
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.logout, color: Colors.red),
            title: Text("Logout"),
            onTap: _confirmLogout,
          ),
        ],
      ),
    );
  }

  void _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Confirm Logout"),
        content: Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            child: Text("Cancel"),
            onPressed: () => Navigator.pop(context, false),
          ),
          TextButton(
            child: Text("Logout", style: TextStyle(color: Colors.red)),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      Navigator.pushReplacementNamed(context, '/');
    }
  }
}
