import 'package:flutter/material.dart';
import '../../services/user_service.dart';
import '../../services/favorite_service.dart';
import '../../services/history_service.dart';
import '../../core/api_client.dart'; // import ตัวกระจายสัญญาณ
import '../Login.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // State
  Map<String, dynamic>? _profile;
  int _reviewsCount = 0;
  int _favoritesCount = 0;

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    // ดักรับสัญญาณรีเฟรชจากหน้าอื่น
    dataRefreshNotifier.addListener(_onDataChanged);
  }

  @override
  void dispose() {
    // คืนค่า
    dataRefreshNotifier.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
    if (mounted) _loadProfile(); // โหลดใหม่เมื่อมีสัญญาณ
  }

  Future<void> _loadProfile() async {
    try {
      final results = await Future.wait([
        ApiService.getProfile(),
        fetchMyReviews(),
        fetchMyFavorites(),
      ]);

      if (mounted) {
        setState(() {
          _profile = results[0] as Map<String, dynamic>;
          _reviewsCount = (results[1] as List).length;
          _favoritesCount = (results[2] as List).length;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _logout() async {
    await ApiService.clearToken();
    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const Login()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: _buildAppBar(context),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'เกิดข้อผิดพลาด\n$_errorMessage',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _errorMessage = null;
                });
                _loadProfile();
              },
              child: const Text('ลองใหม่'),
            ),
          ],
        ),
      );
    }

    final username = _profile?['username'] ?? '-';
    final email = _profile?['email'] ?? '-';
    final bio = _profile?['bio'] ?? '';
    final createdAt = _profile?['created_at'] ?? '';

    return RefreshIndicator(
      onRefresh: _loadProfile,
      color: Colors.white,
      backgroundColor: Colors.grey[900],
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Center(
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Color(0xFFFFCCBC),
                  shape: BoxShape.circle,
                ),
                child: const CircleAvatar(
                  radius: 50,
                  backgroundImage: AssetImage("assets/icons/funny_emoji.png"),
                  backgroundColor: Colors.transparent,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              username,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              email,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
            if (bio.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                bio,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white54, fontSize: 13),
              ),
            ],
            const SizedBox(height: 40),

            // นำยอดจำนวนเข้าไปแสดงใน UI เดิมของคุณแล้วครับ!
            _buildStatRow("REVIEWS", "$_reviewsCount"),
            _buildStatRow("FAVORITES", "$_favoritesCount"),

            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                createdAt.isNotEmpty ? "สร้างบัญชีเมื่อ: $createdAt" : "",
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _logout,
                child: const Text(
                  "LOG OUT",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const Divider(color: Colors.white24, height: 1),
      ],
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading:
          false, // ป้องกันการสร้างปุ่ม Back ตอนอยู่บน Bottom Nav
      actions: [
        IconButton(
          onPressed: _logout,
          icon: const Icon(Icons.login_outlined, color: Colors.white),
        ),
      ],
    );
  }
}
