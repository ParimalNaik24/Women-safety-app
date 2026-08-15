import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import 'otp_verify_screen.dart';
import 'home_screen.dart';

/// First screen shown if not logged in. Collects ONLY name + phone number
/// (no email, no password) and sends an OTP via Firebase Phone Auth.
class PhoneAuthScreen extends StatefulWidget {
  const PhoneAuthScreen({super.key});

  @override
  State<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen> {
  final _authService = AuthService();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;

  Future<void> _sendOtp() async {
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

    // Firebase Phone Auth needs full international format. Hardcoding +91
    // since this project targets Indian users -- add a country picker if
    // you ever need multi-country support.
    final fullPhoneNumber = '+91$phoneDigits';

    setState(() => _isLoading = true);

    await _authService.startPhoneVerification(
      phoneNumber: fullPhoneNumber,
      onCodeSent: (verificationId, resendToken) {
        setState(() => _isLoading = false);
        if (!mounted) return;
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => OtpVerifyScreen(
            verificationId: verificationId,
            phoneNumber: fullPhoneNumber,
            fullName: name,
          ),
        ));
      },
      onAutoVerified: (credential) async {
        // Some devices auto-detect the SMS and verify without user input.
        try {
          await _authService.signInWithCredential(credential, name);
          if (!mounted) return;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        } catch (e) {
          setState(() => _isLoading = false);
          _showMessage(e.toString());
        }
      },
      onFailed: (message) {
        setState(() => _isLoading = false);
        _showMessage(message);
      },
    );
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
              const SizedBox(height: 48),
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
              const Text(
                "We'll send a 6-digit verification code via SMS to confirm this number.",
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isLoading ? null : _sendOtp,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: const Color(0xFF8E24AA),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Send OTP'),
              ),
              if (_isLoading) const Padding(
                padding: EdgeInsets.only(top: 16),
                child: Center(child: CircularProgressIndicator()),
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
