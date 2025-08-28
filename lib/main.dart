import 'package:flutter/material.dart';
import 'package:rive/rive.dart';
import 'package:login_with_animation/screens/login_screen.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const LoginScreen()
    );
  }
}
