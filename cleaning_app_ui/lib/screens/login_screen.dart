import 'package:flutter/material.dart';
import '../services/api_services.dart';
import 'admin_dashboard.dart';
import 'cleaner_dashboard.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    
    try {
      final data = await ApiService.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (data != null) {
        _navigateBasedOnRole(data);
      } else {
        _showError("Invalid credentials. Please try again.");
      }
    } catch (e) {
      _showError("Connection error. Please try again.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _navigateBasedOnRole(Map<String, dynamic> data) {
    final role = data['user']['role'];
    final token = data['token'];

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => role == 'admin' 
            ? AdminDashboard(token: token)
            : CleanerDashboard(), // Update with your Cleaner dashboard
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildWelcomeHeader(),
              SizedBox(height: 40),
              _buildLoginForm(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    return Column(
      children: [
        Icon(Icons.cleaning_services, size: 100, color: Colors.blueAccent),
        SizedBox(height: 16),
        Text(
          "Welcome Back!",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey[800],
          ),
        ),
        SizedBox(height: 8),
        Text(
          "Sign in to manage your cleaning schedule",
          style: TextStyle(
            fontSize: 16,
            color: Colors.blueGrey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _emailController,
            decoration: InputDecoration(
              labelText: "Email Address",
              prefixIcon: Icon(Icons.email_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[400]!),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: (value) => value!.contains('@') 
                ? null 
                : "Please enter a valid email",
          ),
          SizedBox(height: 20),
          TextFormField(
            controller: _passwordController,
            decoration: InputDecoration(
              labelText: "Password",
              prefixIcon: Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword 
                      ? Icons.visibility_off_outlined 
                      : Icons.visibility_outlined,
                  color: Colors.grey,
                ),
                onPressed: () => setState(
                  () => _obscurePassword = !_obscurePassword,
                ),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[400]!),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            validator: (value) => value!.length >= 6
                ? null
                : "Password must be at least 6 characters",
            onFieldSubmitted: (_) => _handleLogin(),
          ),
          SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleLogin,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
              ),
              child: _isLoading
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      "SIGN IN",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
