import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';

class OtpVerifyScreen extends StatefulWidget {
  final String verificationId;
  final String phoneNumber;
  final String fullName;

  const OtpVerifyScreen({
    super.key,
    required this.verificationId,
    required this.phoneNumber,
    required this.fullName,
  });

  @override
  State<OtpVerifyScreen> createState() => _OtpVerifyScreenState();
}

class _OtpVerifyScreenState extends State<OtpVerifyScreen> {
  final _authService = AuthService();
  final _codeController = TextEditingController();
  late String _verificationId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _verificationId = widget.verificationId;
  }

  Future<void> _verifyCode() async {
    final code = _codeController.text.trim();
    if (code.length != 6) {
      _showMessage('Enter the 6-digit code');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final credential = _authService.buildCredential(_verificationId, code);
      await _authService.signInWithCredential(credential, widget.fullName);
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false, // clear the auth screens from the back stack
      );
    } catch (e) {
      setState(() => _isLoading = false);
      _showMessage('Incorrect code, please try again');
    }
  }

  Future<void> _resendOtp() async {
    setState(() => _isLoading = true);
    await _authService.startPhoneVerification(
      phoneNumber: widget.phoneNumber,
      onCodeSent: (verificationId, resendToken) {
        setState(() {
          _isLoading = false;
          _verificationId = verificationId;
        });
        _showMessage('OTP resent');
      },
      onAutoVerified: (credential) async {
        try {
          await _authService.signInWithCredential(credential, widget.fullName);
          if (!mounted) return;
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
            (route) => false,
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
                'Verify OTP',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF8E24AA)),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter the 6-digit code sent to ${widget.phoneNumber}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _codeController,
                decoration: const InputDecoration(labelText: '6-digit code', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20, letterSpacing: 4),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isLoading ? null : _verifyCode,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: const Color(0xFF8E24AA),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Verify & Continue'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _isLoading ? null : _resendOtp,
                child: const Text("Didn't get a code? Resend OTP"),
              ),
              if (_isLoading) const Padding(
                padding: EdgeInsets.only(top: 8),
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
    _codeController.dispose();
    super.dispose();
  }
}
