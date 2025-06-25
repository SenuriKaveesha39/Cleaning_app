import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb
import '../services/api_services.dart';

class CleanerDashboard extends StatefulWidget {
  @override
  _CleanerDashboardState createState() => _CleanerDashboardState();
}

class _CleanerDashboardState extends State<CleanerDashboard> {
  Timer? _timer;
  String currentTime = '';
  bool isClockedIn = false;
  List sessionsToday = [];
  String workedToday = '0h 0m';
  List<Map<String, dynamic>> weekHistory = [];
  bool loading = true;
  String statusMessage = '';
  String? userName;
  String? userEmail;
  String? profilePicPath; // Local file path or network URL

  @override
  void initState() {
    super.initState();
    _loadUserDetails();
    _startClock();
    _refreshData();
  }

  Future<void> _loadUserDetails() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString('userName') ?? 'Cleaner';
      userEmail = prefs.getString('userEmail') ?? '';
      profilePicPath = prefs.getString('profilePic') ?? '';
    });
  }

  Future<void> _pickProfilePic() async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Profile picture change is not supported on web.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) {
      setState(() {
        profilePicPath = picked.path;
      });
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profilePic', picked.path);
      // Optionally: upload to backend and update user's profilePic URL in DB.
    }
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

  Future<void> _refreshData() async {
    setState(() { loading = true; });
    await _fetchTodayStatus();
    await _fetchWeekHistory();
    setState(() { loading = false; });
  }

  Future<void> _fetchTodayStatus() async {
    final status = await ApiService.getTodayClockStatus();
    final sessions = status['sessions'] ?? [];
    sessionsToday = sessions;

    isClockedIn = sessions.isNotEmpty && sessions.last['clockIn'] != null && sessions.last['clockOut'] == null;

    Duration total = Duration.zero;
    for (var s in sessions) {
      if (s['clockIn'] != null && s['clockOut'] != null) {
        final inTime = DateTime.parse(s['clockIn']);
        final outTime = DateTime.parse(s['clockOut']);
        total += outTime.difference(inTime);
      }
    }
    setState(() {
      workedToday = '${total.inHours}h ${total.inMinutes % 60}m';
    });
  }

  Future<void> _fetchWeekHistory() async {
    final history = await ApiService.getClockHistory();
    history.sort((a, b) => b['date'].compareTo(a['date']));
    setState(() {
      weekHistory = history.take(7).toList();
    });
  }

  Future<void> _toggleClock() async {
    final success = await ApiService.toggleClockInOut(isClockedIn);
    if (success) {
      setState(() {
        statusMessage = isClockedIn ? "Clocked Out" : "Clocked In";
      });
      await _refreshData();
    } else {
      setState(() {
        statusMessage = "Clock action failed!";
      });
    }
    Future.delayed(Duration(seconds: 2), () {
      setState(() { statusMessage = ''; });
    });
  }

  Widget _buildTodaySessions() {
    if (sessionsToday.isEmpty) {
      return Center(child: Text("No clock sessions today.", style: TextStyle(color: Colors.grey)));
    }
    return Column(
      children: sessionsToday.map<Widget>((session) {
        final inTime = session['clockIn'] != null
            ? DateFormat('hh:mm a').format(DateTime.parse(session['clockIn']).toLocal())
            : '--';
        final outTime = session['clockOut'] != null
            ? DateFormat('hh:mm a').format(DateTime.parse(session['clockOut']).toLocal())
            : '--';
        String duration = '--';
        if (session['clockIn'] != null && session['clockOut'] != null) {
          final start = DateTime.parse(session['clockIn']);
          final end = DateTime.parse(session['clockOut']);
          final diff = end.difference(start);
          duration = '${diff.inHours}h ${diff.inMinutes % 60}m';
        } else if (session['clockIn'] != null) {
          duration = "In Progress";
        }
        return Container(
          margin: EdgeInsets.symmetric(vertical: 6),
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("In: $inTime", style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.bold)),
                    Text("Out: $outTime", style: TextStyle(color: Colors.red[700], fontWeight: FontWeight.bold)),
                  ]),
              Text(duration, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildWeekHistory() {
    if (weekHistory.isEmpty) {
      return Center(child: Text("No clock history.", style: TextStyle(color: Colors.grey)));
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: weekHistory.length,
      itemBuilder: (context, index) {
        final entry = weekHistory[index];
        final date = DateFormat('EEE, MMM d').format(DateTime.parse(entry['date']));
        final sessions = entry['sessions'] as List<dynamic>? ?? [];
        Duration total = Duration.zero;
        for (var s in sessions) {
          if (s['clockIn'] != null && s['clockOut'] != null) {
            final inTime = DateTime.parse(s['clockIn']);
            final outTime = DateTime.parse(s['clockOut']);
            total += outTime.difference(inTime);
          }
        }
        return Card(
          margin: EdgeInsets.symmetric(vertical: 6),
          child: ListTile(
            title: Text(date, style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(
              "Sessions: ${sessions.length}   Worked: ${total.inHours}h ${total.inMinutes % 60}m",
              style: TextStyle(color: Colors.blueGrey[700]),
            ),
            trailing: Icon(Icons.chevron_right),
            onTap: () => _showDaySessions(context, date, sessions),
          ),
        );
      },
    );
  }

  void _showDaySessions(BuildContext context, String date, List sessions) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(date, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(height: 16),
              ...sessions.map<Widget>((session) {
                final inTime = session['clockIn'] != null
                    ? DateFormat('hh:mm a').format(DateTime.parse(session['clockIn']).toLocal())
                    : '--';
                final outTime = session['clockOut'] != null
                    ? DateFormat('hh:mm a').format(DateTime.parse(session['clockOut']).toLocal())
                    : '--';
                String duration = '--';
                if (session['clockIn'] != null && session['clockOut'] != null) {
                  final start = DateTime.parse(session['clockIn']);
                  final end = DateTime.parse(session['clockOut']);
                  final diff = end.difference(start);
                  duration = '${diff.inHours}h ${diff.inMinutes % 60}m';
                } else if (session['clockIn'] != null) {
                  duration = "In Progress";
                }
                return ListTile(
                  leading: Icon(Icons.access_time, color: Colors.blueAccent),
                  title: Text("In: $inTime   Out: $outTime"),
                  subtitle: Text("Duration: $duration"),
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildClockButton() {
    return ElevatedButton.icon(
      icon: Icon(isClockedIn ? Icons.logout : Icons.login, color: Colors.white),
      label: Text(isClockedIn ? "Clock Out" : "Clock In"),
      style: ElevatedButton.styleFrom(
        backgroundColor: isClockedIn ? Colors.redAccent : Colors.green,
        padding: EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 4,
      ),
      onPressed: loading ? null : _toggleClock,
    );
  }

  Drawer _buildAppDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(userName ?? 'Cleaner'),
            accountEmail: Text(userEmail ?? ''),
            currentAccountPicture: GestureDetector(
              onTap: _pickProfilePic,
              child: CircleAvatar(
                backgroundColor: Colors.white,
                backgroundImage: (profilePicPath != null && profilePicPath!.isNotEmpty)
                    ? (profilePicPath!.startsWith('http')
                        ? NetworkImage(profilePicPath!)
                        : FileImage(File(profilePicPath!)) as ImageProvider)
                    : null,
                child: (profilePicPath == null || profilePicPath!.isEmpty)
                    ? Icon(Icons.person, size: 48, color: Colors.blueAccent)
                    : null,
              ),
            ),
            decoration: BoxDecoration(color: Colors.blueAccent),
          ),
          ListTile(
            leading: Icon(Icons.logout, color: Colors.red),
            title: Text("Logout"),
            onTap: () async {
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
            },
          ),
        ],
      ),
    );
  }

  Widget _infoBox(String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        SizedBox(height: 6),
        Text(title, style: TextStyle(fontSize: 14, color: Colors.grey[700])),
        SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildUserInfoHeader() {
    return Row(
      children: [
        GestureDetector(
          onTap: _pickProfilePic,
          child: CircleAvatar(
            radius: 28,
            backgroundColor: Colors.blue[100],
            backgroundImage: (profilePicPath != null && profilePicPath!.isNotEmpty)
                ? (profilePicPath!.startsWith('http')
                    ? NetworkImage(profilePicPath!)
                    : FileImage(File(profilePicPath!)) as ImageProvider)
                : null,
            child: (profilePicPath == null || profilePicPath!.isEmpty)
                ? Icon(Icons.person, color: Colors.blueAccent, size: 32)
                : null,
          ),
        ),
        SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(userName ?? 'Cleaner', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text(userEmail ?? '', style: TextStyle(color: Colors.grey[700], fontSize: 13)),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text("Cleaner Dashboard"),
        elevation: 2,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            tooltip: "Refresh",
            onPressed: _refreshData,
          ),
        ],
      ),
      drawer: _buildAppDrawer(),
      body: loading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refreshData,
              child: SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildUserInfoHeader(),
                    SizedBox(height: 18),
                    Center(
                      child: Text(
                        currentTime,
                        style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.blueGrey[900]),
                      ),
                    ),
                    SizedBox(height: 18),
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _infoBox('Worked Today', workedToday, Icons.timer, Colors.blueAccent),
                                _infoBox('Status', isClockedIn ? "Clocked In" : "Clocked Out", isClockedIn ? Icons.play_circle : Icons.pause_circle, isClockedIn ? Colors.green : Colors.redAccent),
                              ],
                            ),
                            SizedBox(height: 12),
                            _buildClockButton(),
                            if (statusMessage.isNotEmpty) ...[
                              SizedBox(height: 8),
                              Text(statusMessage, style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
                            ],
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    Text("Today's Sessions", style: Theme.of(context).textTheme.titleLarge),
                    SizedBox(height: 8),
                    _buildTodaySessions(),
                    SizedBox(height: 22),
                    Text("Past 7 Days", style: Theme.of(context).textTheme.titleLarge),
                    SizedBox(height: 8),
                    _buildWeekHistory(),
                  ],
                ),
              ),
            ),
    );
  }
}
