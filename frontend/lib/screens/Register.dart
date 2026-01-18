import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;

class Register extends StatefulWidget {
  const Register({super.key});

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  // Controller
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _bioController = TextEditingController();

  // แก้เป็น List เพื่อเก็บได้หลายค่า
  final List<String> _selectedGenres = [];

  // รายชื่อแนวเพลง
  final List<String> _genres = [
    'Pop',
    'Rock',
    'Hip Hop',
    'R&B',
    'Jazz',
    'K-Pop',
    'Indie',
    'Classical',
    'Metal',
    'EDM',
  ];

  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  // Register Function
  Future<void> _register() async {
    // Validation
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showMessage("Please fill all fields", isError: true);
      return;
    }

    // ✅ 2. เช็คว่าเลือกแนวเพลงอย่างน้อย 1 อัน
    if (_selectedGenres.isEmpty) {
      _showMessage("Please select at least one genre", isError: true);
      return;
    }

    if (_passwordController.text != _confirmController.text) {
      _showMessage("Password does not match", isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // URL (Android Emulator = 10.0.2.2)
    final url = Uri.parse('http://10.0.2.2:8000/users/register/');

    // Auto Username: สร้างจาก Email (ตัด @ ออก)
    String autoUsername = _emailController.text.split('@')[0];

    // If bio null fill the '-' inside
    String bioValue = _bioController.text.isEmpty ? "-" : _bioController.text;

    // ✅ 3. แปลง List เป็น String (เช่น "Pop, Rock") ส่งไป Backend
    String genreString = _selectedGenres.join(', ');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _emailController.text,
          'password': _passwordController.text,
          'username': autoUsername,
          'favorite_genres': genreString, // ส่งค่าที่แปลงแล้ว
          'bio': bioValue,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showMessage("Success! Please Sign in", isError: false);
        Navigator.pop(context); // Back to Login page
      } else {
        var errorData = jsonDecode(response.body);
        // เช็คว่า error key ชื่อ detail หรือเปล่า (FastAPI default)
        String errMsg = errorData['detail'] ?? "Registration Failed";
        _showMessage("Failed: $errMsg", isError: true);
      }
    } catch (e) {
      print(e);
      _showMessage("Can't connect to server", isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(36, 36, 35, 1),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(height: 10),

              const Text(
                'Create Account',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),

              // Email
              _buildLabel('Email'),
              _buildTextField(_emailController, 'username@mail.com', false),

              // Password
              _buildLabel('Password'),
              _buildTextField(_passwordController, '********', true),

              // Confirm Password
              _buildLabel('Confirm Password'),
              _buildTextField(_confirmController, '********', true),

              // ✅ 4. Favorite Genre (เปลี่ยนเป็น Multi-Select Chips)
              _buildLabel('Favorite Genres (Select multiple)'),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Wrap(
                  spacing: 8.0, // ระยะห่างแนวนอน
                  runSpacing: 4.0, // ระยะห่างแนวตั้ง
                  children: _genres.map((String genre) {
                    final isSelected = _selectedGenres.contains(genre);
                    return FilterChip(
                      label: Text(genre),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.black : Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      selected: isSelected,
                      selectedColor: const Color(0xFF1DB954),
                      backgroundColor: Colors.grey[800],
                      checkmarkColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(color: Colors.transparent),
                      ),
                      onSelected: (bool selected) {
                        setState(() {
                          if (selected) {
                            _selectedGenres.add(genre);
                          } else {
                            _selectedGenres.remove(genre);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),

              // Bio
              _buildLabel('Bio (Tell us about yourself)'),
              TextField(
                controller: _bioController,
                style: const TextStyle(color: Colors.white),
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Your bio...',
                  hintStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: Colors.white10,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Register Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1DB954),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.black)
                      : const Text(
                          'Sign Up',
                          style: TextStyle(
                            color: Colors.black,
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
      ),
    );
  }

  // Helper Widget สำหรับสร้าง Label
  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 10),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 16),
      ),
    );
  }

  // Helper Widget สำหรับสร้าง TextField
  Widget _buildTextField(
    TextEditingController controller,
    String hint,
    bool isPassword,
  ) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white54),
        filled: true,
        fillColor: Colors.white10,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 15,
        ),
      ),
    );
  }
}
