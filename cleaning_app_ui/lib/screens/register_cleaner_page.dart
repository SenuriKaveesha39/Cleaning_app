import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RegisterCleanerPage extends StatefulWidget {
  final String adminToken;

  const RegisterCleanerPage({required this.adminToken});

  @override
  _RegisterCleanerPageState createState() => _RegisterCleanerPageState();
}

class _RegisterCleanerPageState extends State<RegisterCleanerPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String _message = '';
  Color _messageColor = Colors.transparent;

  Future<void> _registerCleaner() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _message = '';
    });

    try {
      final baseUrl = kIsWeb 
          ? 'http://localhost:5000'
          : 'http://10.0.2.2:5000';
      
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/register-cleaner'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.adminToken}',
        },
        body: json.encode({
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'password': _passwordController.text.trim(),
        }),
      );

      final responseData = json.decode(response.body);
      if (response.statusCode == 201) {
        _showSuccess('Cleaner registered successfully!');
        _clearForm();
      } else {
        _showError(responseData['message'] ?? 'Registration failed');
      }
    } catch (e) {
      _showError('Connection error. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccess(String message) {
    _messageColor = Colors.green;
    _message = message;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      )
    );
  }

  void _showError(String message) {
    _messageColor = Colors.red;
    _message = message;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      )
    );
  }

  void _clearForm() {
    _nameController.clear();
    _emailController.clear();
    _passwordController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register New Cleaner'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 32),
            _buildRegistrationForm(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Icon(Icons.person_add_alt_1, size: 80, color: Colors.blueAccent),
        const SizedBox(height: 16),
        Text(
          'Add New Team Member',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey[800],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Enter cleaner details to create a new account',
          style: TextStyle(
            fontSize: 16,
            color: Colors.blueGrey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildRegistrationForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Full Name',
              prefixIcon: const Icon(Icons.person_outline),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            textInputAction: TextInputAction.next,
            validator: (value) => value!.isEmpty ? 'Please enter a name' : null,
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _emailController,
            decoration: InputDecoration(
              labelText: 'Email Address',
              prefixIcon: const Icon(Icons.email_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: (value) => value!.contains('@') 
                ? null 
                : 'Please enter a valid email',
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _passwordController,
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            obscureText: true,
            textInputAction: TextInputAction.done,
            validator: (value) => value!.length >= 6
                ? null
                : 'Password must be at least 6 characters',
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _registerCleaner,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'CREATE ACCOUNT',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          if (_message.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              _message,
              style: TextStyle(
                color: _messageColor,
                fontWeight: FontWeight.w500,
              ),
            )
          ]
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
