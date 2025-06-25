import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'register_cleaner_page.dart';

class AdminDashboard extends StatefulWidget {
  final String token;

  const AdminDashboard({required this.token});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  late Future<List<Map<String, dynamic>>> _cleanersFuture;

  @override
  void initState() {
    super.initState();
    _cleanersFuture = fetchCleaners();
  }

  String get apiBaseUrl =>
      kIsWeb ? 'http://localhost:5000' : 'http://10.0.2.2:5000';

  Future<List<Map<String, dynamic>>> fetchCleaners() async {
    final uri = Uri.parse('$apiBaseUrl/api/admin/cleaners');
    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer ${widget.token}',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to load cleaners');
    }
  }

  Future<List<Map<String, dynamic>>> fetchCleanerClockHistory(String cleanerId) async {
    final uri = Uri.parse('$apiBaseUrl/api/admin/cleaner/$cleanerId/clock-history');
    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer ${widget.token}',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to load clock history');
    }
  }

  Future<void> generateAndDownloadPdf({
    required BuildContext context,
    required Map<String, dynamic> cleaner,
    required List<Map<String, dynamic>> history,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        build: (pw.Context context) => [
          pw.Header(
            level: 0,
            child: pw.Text('Work Summary for ${cleaner['name'] ?? ''}', style: pw.TextStyle(fontSize: 24)),
          ),
          pw.Text('Email: ${cleaner['email'] ?? ''}'),
          pw.Text('Phone: ${cleaner['phone'] ?? ''}'),
          pw.SizedBox(height: 16),
          pw.Table.fromTextArray(
            headers: ['Date', 'Clock In', 'Clock Out'],
            data: [
              for (final entry in history)
                ...((entry['sessions'] as List?)?.map((session) => [
                  entry['date'] ?? '',
                  session['clockIn'] ?? '--',
                  session['clockOut'] ?? '--',
                ]) ?? [])
            ],
            cellStyle: pw.TextStyle(fontSize: 12),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14),
            headerDecoration: pw.BoxDecoration(color: PdfColors.grey300),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'work_summary_${cleaner['name'] ?? 'cleaner'}.pdf',
    );
  }

  void _showCleanerHistory(BuildContext context, Map<String, dynamic> cleaner) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return FutureBuilder<List<Map<String, dynamic>>>(
          future: fetchCleanerClockHistory(cleaner['_id']),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Padding(
                padding: const EdgeInsets.all(32.0),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.all(32.0),
                child: Center(child: Text("Error: ${snapshot.error}")),
              );
            }
            final history = snapshot.data!;
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    cleaner['name'] ?? 'Cleaner Details',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 12),
                  Text(
                    cleaner['email'] ?? '',
                    style: TextStyle(fontSize: 16, color: Colors.blueGrey[700]),
                  ),
                  SizedBox(height: 8),
                  Text(
                    cleaner['phone'] ?? '',
                    style: TextStyle(fontSize: 16, color: Colors.blueGrey[700]),
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton.icon(
                        icon: Icon(Icons.download),
                        label: Text('Download PDF'),
                        onPressed: () async {
                          await generateAndDownloadPdf(
                            context: context,
                            cleaner: cleaner,
                            history: history,
                          );
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Text(
                    "Clock History",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(height: 8),
                  if (history.isEmpty)
                    Text("No clock history found."),
                  if (history.isNotEmpty)
                    SizedBox(
                      height: 300,
                      child: ListView.builder(
                        itemCount: history.length,
                        itemBuilder: (context, index) {
                          final entry = history[index];
                          final date = entry['date'] ?? '';
                          final sessions = entry['sessions'] as List<dynamic>? ?? [];
                          return Card(
                            margin: EdgeInsets.symmetric(vertical: 6),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    date,
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blueAccent),
                                  ),
                                  ...sessions.map((s) {
                                    final clockIn = s['clockIn'] ?? '--';
                                    final clockOut = s['clockOut'] ?? '--';
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 4.0),
                                      child: Text(
                                        'In: $clockIn   Out: $clockOut',
                                        style: TextStyle(fontSize: 14),
                                      ),
                                    );
                                  }).toList(),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Admin Dashboard"),
        elevation: 2,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            tooltip: "Refresh",
            onPressed: () {
              setState(() {
                _cleanersFuture = fetchCleaners();
              });
            },
          ),
          IconButton(
            icon: Icon(Icons.logout),
            tooltip: "Logout",
            onPressed: () async {
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
                Navigator.pushReplacementNamed(context, '/');
              }
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
          child: Column(
            children: [
              SizedBox(height: 16),
              CircleAvatar(
                radius: 36,
                backgroundColor: Colors.blue[100],
                child: Icon(Icons.admin_panel_settings, size: 48, color: Colors.blueAccent),
              ),
              SizedBox(height: 16),
              Text(
                "Welcome, Admin!",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blueGrey[800]),
              ),
              SizedBox(height: 8),
              Text(
                "Manage your cleaning team and operations",
                style: TextStyle(fontSize: 16, color: Colors.blueGrey[600]),
              ),
              SizedBox(height: 32),

              // Register Cleaner Card
              Card(
                margin: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  leading: Icon(Icons.person_add_alt_1, color: Colors.blueAccent, size: 32),
                  title: Text("Register New Cleaner", style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text("Add a new cleaner to your team"),
                  trailing: Icon(Icons.arrow_forward_ios, color: Colors.blueAccent),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RegisterCleanerPage(adminToken: widget.token),
                      ),
                    );
                  },
                ),
              ),

              SizedBox(height: 24),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Your Cleaners",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey[700]),
                ),
              ),
              SizedBox(height: 8),

              FutureBuilder<List<Map<String, dynamic>>>(
                future: _cleanersFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting)
                    return Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Center(child: CircularProgressIndicator()),
                    );

                  if (snapshot.hasError)
                    return Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("Error: ${snapshot.error}"),
                            SizedBox(height: 12),
                            ElevatedButton.icon(
                              icon: Icon(Icons.refresh),
                              label: Text("Retry"),
                              onPressed: () {
                                setState(() {
                                  _cleanersFuture = fetchCleaners();
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    );

                  final cleaners = snapshot.data!;
                  if (cleaners.isEmpty)
                    return Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Center(child: Text("No cleaners found.")),
                    );

                  return Column(
                    children: cleaners.map((cleaner) {
                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                        child: ListTile(
                          leading: Icon(Icons.cleaning_services, color: Colors.green),
                          title: Text(cleaner['name'] ?? 'Unnamed Cleaner'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Email: ${cleaner['email'] ?? 'N/A'}"),
                              Text("Phone: ${cleaner['phone'] ?? 'N/A'}"),
                            ],
                          ),
                          trailing: Icon(Icons.arrow_forward_ios),
                          onTap: () {
                            _showCleanerHistory(context, cleaner);
                          },
                        ),
                      );
                    }).toList(),
                  );
                },
              ),

              SizedBox(height: 32),
              Text(
                "© 2025 Clean Team Pro",
                style: TextStyle(color: Colors.blueGrey[300]),
              ),
              SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
