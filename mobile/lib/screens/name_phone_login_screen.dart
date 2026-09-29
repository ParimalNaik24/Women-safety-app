import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/auth_service.dart';
import 'home_screen.dart';

class NamePhoneLoginScreen extends StatefulWidget {
  const NamePhoneLoginScreen({super.key});

  @override
  State<NamePhoneLoginScreen> createState() => _NamePhoneLoginScreenState();
}

class _NamePhoneLoginScreenState extends State<NamePhoneLoginScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  Future<void> _submitData() async {
    String name = _nameController.text.trim();
    String phone = _phoneController.text.trim();

    if (name.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in both fields')),
      );
      return;
    }

    RegExp phoneRegex = RegExp(r'^[789]\d{9}$');
    if (!phoneRegex.hasMatch(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid 10-digit number starting with 7, 8, or 9')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Primary save -- Firestore. The app's actual auth/data source.
      // If this fails, we stop and show an error, since login truly failed.
      await _authService.loginWithNameAndPhone(
        fullName: name,
        phoneNumber: phone,
      );

      // 2. Secondary save -- best-effort mirror to the Postgres backend
      // via Spring Boot, purely so records are visible in pgAdmin too.
      // Wrapped separately so a failure here never blocks login.
      _syncToPostgresBackend(name: name, phone: phone);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Fire-and-forget sync to the Spring Boot backend so the same record
  // also shows up in pgAdmin. Errors are swallowed on purpose --
  // this must never break login if the backend isn't running.
  void _syncToPostgresBackend({required String name, required String phone}) {
    http
        .post(
          Uri.parse('http://10.0.2.2:8080/api/users/login'),
          headers: {'Content-Type': 'application/json; charset=UTF-8'},
          body: jsonEncode({'name': name, 'number': phone}),
        )
        .then((response) {
      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('Synced to Postgres backend successfully.');
      } else {
        debugPrint('Postgres sync failed: ${response.statusCode}');
      }
    }).catchError((e) {
      debugPrint('Postgres backend unreachable, skipping sync: $e');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Women Safety App'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Enter your name and phone number to continue.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              decoration: const InputDecoration(
                labelText: '10-digit phone number',
                prefixText: '+91 ',
                border: OutlineInputBorder(),
                counterText: "",
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8E24AA),
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Continue', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}