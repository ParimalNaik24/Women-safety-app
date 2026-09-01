import 'package:flutter/material.dart';
import 'screens/name_phone_login_screen.dart';

void main() {
  runApp(const WomenSafetyApp());
}

class WomenSafetyApp extends StatelessWidget {
  const WomenSafetyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Women Safety App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF8E24AA),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF8E24AA)),
        useMaterial3: true,
      ),
      home: const NamePhoneLoginScreen(),
    );
  }
}