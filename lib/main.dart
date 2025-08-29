import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const PressConnectApp());
}

class PressConnectApp extends StatelessWidget {
  const PressConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Press Connect',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}