import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';

class NamePhoneLoginScreen extends StatefulWidget {
  const NamePhoneLoginScreen({super.key});

  @override
  State<NamePhoneLoginScreen> createState() => _NamePhoneLoginScreenState();
}

class _NamePhoneLoginScreenState extends State<NamePhoneLoginScreen> {
  final _authService = AuthService();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    final name = _nameController.text.trim();
    final phoneDigits = _phoneController.text.trim();

    if (name.isEmpty) {
      _showMessage('Please enter your name');
      return;
    }
    if (phoneDigits.length != 10) {
      _showMessage('Enter a valid 10-digit phone number');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _authService.loginWithNameAndPhone(
        fullName: name,
        phoneNumber: '+91$phoneDigits',
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      _showMessage('Login failed: $e');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 64),
              const Text(
                'Women Safety App',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF8E24AA)),
              ),
              const SizedBox(height: 8),
              const Text(
                'Enter your name and phone number to continue',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder()),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: '10-digit phone number',
                  prefixText: '+91  ',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                maxLength: 10,
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _isLoading ? null : _login,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: const Color(0xFF8E24AA),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Continue'),
              ),
              if (_isLoading) const Padding(
  padding: EdgeInsets.only(top: 16),
  child: Column(
    children: [
      CircularProgressIndicator(),
      SizedBox(height: 8),
      Text('Setting up your session...', style: TextStyle(color: Colors.grey, fontSize: 12)),
    ],
  ),
),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}