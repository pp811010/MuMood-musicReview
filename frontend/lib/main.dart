import 'package:flutter/material.dart';
import 'package:frontend/screens/Login.dart';
import 'package:frontend/screens/admin/admin_app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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

      // เผื่อใช้
      routes: {
        '/login': (context) => const Login(),
        '/admin' : (context) => const AdminApp(),
      },
    );
  }
}
