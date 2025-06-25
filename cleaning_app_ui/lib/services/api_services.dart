import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';


class ApiService {
  static const String baseUrl = 'http://localhost:5000/api/auth';

  static Future<Map<String, dynamic>?> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: { 'Content-Type': 'application/json' },
      body: jsonEncode({ 'email': email, 'password': password }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', data['token']);
      await prefs.setString('role', data['user']['role']);
      await prefs.setString('userId', data['user']['id']);
      return data;
    }
    return null;
  }

  static Future<bool> toggleClockInOut(bool isClockedIn) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.post(
      Uri.parse('http://localhost:5000/api/cleaner/clock'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'action': isClockedIn ? 'clock_out' : 'clock_in'}),
    );

    return response.statusCode == 200;
  }


 static Future<Map<String, dynamic>> getTodayClockStatus() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');

  final response = await http.get(
    Uri.parse('http://localhost:5000/api/cleaner/clock'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    // Always return a sessions array for consistency
    return {
      'date': data['date'],
      'sessions': (data['sessions'] as List<dynamic>?)?.map((s) => {
        'clockIn': s['clockIn'],
        'clockOut': s['clockOut'],
      }).toList() ?? [],
    };
  }
  // Return empty sessions array if error
  return {'date': null, 'sessions': []};
}


 static Future<List<Map<String, dynamic>>> getClockHistory() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');

  if (token == null) throw Exception('Auth token not found');

  // For Android emulator use: http://10.0.2.2:5000
  // For web/chrome use: http://localhost:5000
  final uri = Uri.parse('http://localhost:5000/api/cleaner/clock-history');

  final response = await http.get(
    uri,
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
  );

  if (response.statusCode == 200) {
    final List<dynamic> data = json.decode(response.body);
    
    print('Raw API response: ${response.body}');  // Debug raw response
    
    return data.map((e) => {
      'date': e['date'],
      'sessions': (e['sessions'] as List<dynamic>?)
          ?.map((s) => {
            'clockIn': s['clockIn'],
            'clockOut': s['clockOut']
          })
          .toList() ?? [],
    }).toList();
  } else {
    print('Failed to load clock history: ${response.statusCode} ${response.body}');
    throw Exception('Failed to load clock history');
  }
}



static Future<List<Map<String, dynamic>>> getCleaners() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');
  
  if (token == null) throw Exception('Authentication required');

  final baseUrl = kIsWeb 
      ? 'http://localhost:5000'
      : 'http://10.0.2.2:5000'; // For Android emulator

  try {
    final response = await http.get(
      Uri.parse('$baseUrl/api/admin/cleaners'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    print('Cleaners API Response: ${response.statusCode} ${response.body}');
    
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('Failed with status ${response.statusCode}');
  } catch (e) {
    throw Exception('Cleaners fetch failed: ${e.toString()}');
  }
}



}