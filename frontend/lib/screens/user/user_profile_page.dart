import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leadingWidth: 80,
        leading: TextButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 16),
          label: const Text(
            "Back",
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          style: TextButton.styleFrom(padding: const EdgeInsets.only(left: 10)),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.login_outlined, color: Colors.white),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Profile Picture
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
              const Text(
                "Peter",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                "wongsakorn@mail.com",
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),

              const SizedBox(height: 40),

              // Stats Rows with Dividers (Mock Data)
              _buildStatRow("REACTION", "10"),
              _buildStatRow("REVIEWS", "5"),

              const SizedBox(height: 20),
              // Create Account Date
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Create account 15/05/205",
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),

              const SizedBox(height: 40),

              // Logout Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    // Logic Logout
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD50000), 
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    elevation: 0,
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
            ],
          ),
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
}
