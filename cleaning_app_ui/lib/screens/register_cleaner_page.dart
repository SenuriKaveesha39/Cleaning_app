import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RegisterCleanerPage extends StatefulWidget {
  final String adminToken;

  RegisterCleanerPage({required this.adminToken}); // Removed extra param

  @override
  _RegisterCleanerPageState createState() => _RegisterCleanerPageState();
}

class _RegisterCleanerPageState extends State<RegisterCleanerPage> {
  final _formKey = GlobalKey<FormState>();
  String name = '';
  String email = '';
  String password = '';
  String message = '';

  Future<void> registerCleaner() async {
    final url = Uri.parse('http://localhost:5000/api/auth/register-cleaner');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.adminToken}',
        },
        body: json.encode({
          'name': name,
          'email': email,
          'password': password,
        }),
      );

      final responseData = json.decode(response.body);
      if (response.statusCode == 201) {
        setState(() {
          message = 'Cleaner registered successfully!';
        });
      } else {
        setState(() {
          message = responseData['message'] ?? 'Registration failed.';
        });
      }
    } catch (e) {
      setState(() {
        message = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Register Cleaner')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: InputDecoration(labelText: 'Name'),
                onChanged: (val) => name = val,
                validator: (val) => val == null || val.isEmpty ? 'Enter name' : null,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Email'),
                onChanged: (val) => email = val,
                validator: (val) => val == null || !val.contains('@') ? 'Enter valid email' : null,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Password'),
                obscureText: true,
                onChanged: (val) => password = val,
                validator: (val) => val == null || val.length < 6 ? 'Password too short' : null,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    registerCleaner();
                  }
                },
                child: Text('Register Cleaner'),
              ),
              SizedBox(height: 20),
              Text(message),
            ],
          ),
        ),
      ),
    );
  }
}
