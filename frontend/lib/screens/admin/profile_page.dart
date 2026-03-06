import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/screens/Login.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  Future<void> _handleLogout(BuildContext context) async {
    try {
      // 1. เรียก API Logout (ใส่ await เพื่อรอให้ส่งคำสั่งสำเร็จ)
      // หมายเหตุ: ถ้า API พ่น 400/401 ให้ข้ามไปขั้นตอนถัดไปเลย
      await http.post(
        Uri.parse('http://10.0.2.2:8000/users/logout'),
        headers: {
          'Content-Type': 'application/json',
          // 'Authorization': 'Bearer YOUR_TOKEN', // ใส่ถ้ามีระบบ Token
        },
      );
    } catch (e) {
      debugPrint("Logout API error: $e");
    } finally {
      // 2. ล้างข้อมูลในเครื่อง และเปลี่ยนหน้า (ทำใน finally เพื่อให้ทำงานเสมอ)
      if (context.mounted) {
        // ล้างประวัติหน้าจอทั้งหมด และไปที่หน้า /login
        Navigator.pushAndRemoveUntil(
          context,
          // '/login',
          MaterialPageRoute(builder: (context) => const Login()),
          (route) => false, // false หมายถึงลบทุก Route ที่อยู่ใน Stack ออกให้หมด
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              _showLogoutDialog(context);
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 1. ส่วนรูปภาพโปรไฟล์ (Avatar)
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white10, width: 2),
                image: const DecorationImage(
                  image: NetworkImage(
                    "https://www.w3schools.com/howto/img_avatar2.png", // รูปตัวอย่าง
                  ),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 2. ชื่อ Admin
            const Text(
              "Admin",
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 40),

            SizedBox(
              width: 200,
              height: 45,
              child: ElevatedButton(
                onPressed: () => _showLogoutDialog(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  "Log out",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  // ฟังก์ชันแสดงกล่องยืนยันการออกจากระบบ
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text("Log out", style: TextStyle(color: Colors.white)),
        content: const Text(
          "Are you sure you want to log out?",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              _handleLogout(context);
            },
            child: const Text("Confirm", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
