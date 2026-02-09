import 'package:flutter/material.dart';
import '../screens/admin/Inventory_page.dart'; // เปลี่ยนเป็น path ของคุณ
import '../screens/admin/profile_page.dart';   // สร้างหน้า Profile เปล่าๆ ไว้
import './custom_bottom_nav.dart';

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _selectedIndex = 0;

  // รายการหน้าที่ต้องการสลับ
  final List<Widget> _pages = [
    InventoryPage(), 
    const ProfilePage(),  
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ใช้ IndexedStack เพื่อให้เวลาสลับหน้า ข้อมูลที่โหลดไว้ไม่หายไป
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}