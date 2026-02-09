import 'package:flutter/material.dart';
import 'screens/login.dart';
import 'screens/admin/Inventory_page.dart';
import 'widgets/main_wrapper.dart';

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
      home: InventoryPage(),
    );
  }
}
