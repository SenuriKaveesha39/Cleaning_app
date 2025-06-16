import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/api_services.dart';

class CleanerDashboard extends StatefulWidget {
  @override
  _CleanerDashboardState createState() => _CleanerDashboardState();
}

class _CleanerDashboardState extends State<CleanerDashboard> {
  String currentTime = '';
  Timer? _timer;

  bool isClockedIn = false;
  String? clockIn;
  String? clockOut;
  String workedDuration = '0h 0m';

  List<Map<String, dynamic>> pastWeekData = [];
  List<Map<String, dynamic>> clockHistory = [];

  @override
  void initState() {
    super.initState();
    _startClock();
    _fetchTodayStatus();
    _fetchWeeklySummary();
  }

  void _startClock() {
    _updateCurrentTime();
    _timer = Timer.periodic(Duration(seconds: 1), (_) => _updateCurrentTime());
  }

  void _updateCurrentTime() {
    final now = DateTime.now();
    setState(() {
      currentTime = DateFormat('HH:mm:ss').format(now);
    });
  }

  Future<void> _fetchTodayStatus() async {
    final status = await ApiService.getTodayClockStatus();
    final inTime = status['clockIn'] != null ? DateTime.parse(status['clockIn']).toLocal() : null;
    final outTime = status['clockOut'] != null ? DateTime.parse(status['clockOut']).toLocal() : null;

    Duration duration = Duration.zero;
    if (inTime != null && outTime != null) {
      duration = outTime.difference(inTime);
    }

    setState(() {
      isClockedIn = inTime != null && outTime == null;
      clockIn = inTime != null ? DateFormat('HH:mm').format(inTime) : '--';
      clockOut = outTime != null ? DateFormat('HH:mm').format(outTime) : '--';
      workedDuration = '${duration.inHours}h ${duration.inMinutes % 60}m';
    });
  }

  Future<void> _fetchWeeklySummary() async {
    final history = await ApiService.getClockHistory();
    final now = DateTime.now();

    // Sort history for display (newest first)
    history.sort((a, b) => b['date'].compareTo(a['date']));

    // Weekly chart data
    final last7Days = List.generate(7, (i) => now.subtract(Duration(days: i)));
    final data = last7Days.map((day) {
      final formattedDate = DateFormat('yyyy-MM-dd').format(day);
      final dayData = history.firstWhere(
        (e) => e['date'] == formattedDate,
        orElse: () => {},
      );

      final inTime = dayData['clockIn'] != null ? DateTime.parse(dayData['clockIn']).toLocal() : null;
      final outTime = dayData['clockOut'] != null ? DateTime.parse(dayData['clockOut']).toLocal() : null;
      final worked = (inTime != null && outTime != null)
          ? outTime.difference(inTime).inMinutes / 60
          : 0.0;

      return {
        'label': DateFormat('E').format(day),
        'hours': worked,
      };
    }).toList().reversed.toList();

    setState(() {
      clockHistory = history;
      pastWeekData = data;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Widget _buildChart() {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 12,
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) => Text('${value.toInt()}h'),
              reservedSize: 40,
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                return (index < pastWeekData.length)
                    ? Text(pastWeekData[index]['label'])
                    : const Text('');
              },
            ),
          ),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        barGroups: pastWeekData
            .asMap()
            .map((i, d) => MapEntry(
                i,
                BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: d['hours'],
                      color: Colors.blueAccent,
                      width: 16,
                      borderRadius: BorderRadius.circular(4),
                    )
                  ],
                )))
            .values
            .toList(),
      ),
    );
  }


  Widget _buildHistoryList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: clockHistory.length,
      itemBuilder: (context, index) => _historyListItem(clockHistory[index]),
    );
  }

  Widget _historyListItem(Map<String, dynamic> entry) {
    final date = DateTime.parse(entry['date']);
    final clockInTime = entry['clockIn'] != null 
        ? DateFormat.Hm().format(DateTime.parse(entry['clockIn']).toLocal())
        : '--';
        
    final clockOutTime = entry['clockOut'] != null 
        ? DateFormat.Hm().format(DateTime.parse(entry['clockOut']).toLocal())
        : '--';
        
    Duration duration = Duration.zero;
    if (entry['clockIn'] != null && entry['clockOut'] != null) {
      final start = DateTime.parse(entry['clockIn']);
      final end = DateTime.parse(entry['clockOut']);
      duration = end.difference(start);
    }

    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        title: Text(
          DateFormat.yMMMd().format(date),
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Clock In: $clockInTime', 
                      style: TextStyle(color: Colors.green[700])),
                  Text('Clock Out: $clockOutTime',
                      style: TextStyle(color: Colors.red[700])),
                ],
              ),
              SizedBox(height: 6),
              Text('Duration: ${duration.inHours}h ${duration.inMinutes.remainder(60)}m',
                  style: TextStyle(color: Colors.blueGrey[700])),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoBox(String title, String value) {
    return Column(
      children: [
        Text(title, style: TextStyle(fontSize: 14, color: Colors.grey[700])),
        SizedBox(height: 6),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cleaner Dashboard'),
        elevation: 2,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(currentTime, 
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
              ),
              SizedBox(height: 20),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(DateFormat('EEEE, MMM d, yyyy').format(DateTime.now()),
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                      SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _infoBox('Clock In', clockIn ?? '--'),
                          _infoBox('Clock Out', clockOut ?? '--'),
                          _infoBox('Worked', workedDuration),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 30),
              Text('Weekly Worked Hours', 
                  style: Theme.of(context).textTheme.titleLarge),
              SizedBox(height: 200, child: _buildChart()),
              SizedBox(height: 30),
              Text('Work History',
                  style: Theme.of(context).textTheme.titleLarge),
              SizedBox(height: 10),
              _buildHistoryList(),
            ],
          ),
        ),
      ),
    );
  }
}
