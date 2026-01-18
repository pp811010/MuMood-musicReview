import 'package:flutter/material.dart';
import 'package:frontend/screens/Register.dart';
import 'screens/Login.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MuMood',
      theme: ThemeData(),
      home: const Login(),
    );
  }
}
