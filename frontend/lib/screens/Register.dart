import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class Register extends StatefulWidget {
  const Register({super.key});

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _bioController = TextEditingController();

  final List<String> _selectedGenres = [];
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
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  String? _validatePassword(String password) {
    if (password.length < 8) {
      return "Password ต้องมีอย่างน้อย 8 ตัวอักษร";
    }
    if (!password.contains(RegExp(r'[A-Z]'))) {
      return "Password ต้องมีตัวพิมพ์ใหญ่อย่างน้อย 1 ตัว (A-Z)";
    }
    if (!password.contains(RegExp(r'[a-z]'))) {
      return "Password ต้องมีตัวพิมพ์เล็กอย่างน้อย 1 ตัว (a-z)";
    }
    if (!password.contains(RegExp(r'[0-9]'))) {
      return "Password ต้องมีตัวเลขอย่างน้อย 1 ตัว (0-9)";
    }
    return null;
  }

  Future<void> _register() async {
    final email = _emailController.text.trim();

    if (email.isEmpty || _passwordController.text.isEmpty) {
      _showMessage("Please fill in all fields", isError: true);
      return;
    }

    if (!email.contains('@') || !email.toLowerCase().endsWith('.com')) {
      _showMessage(
        "กรุณาใส่ email ให้ถูกต้อง (ต้องมี @ และลงท้ายด้วย .com)",
        isError: true,
      );
      return;
    }

    final passwordError = _validatePassword(_passwordController.text);
    if (passwordError != null) {
      _showMessage(passwordError, isError: true);
      return;
    }

    if (_passwordController.text != _confirmController.text) {
      _showMessage("Passwords do not match", isError: true);
      return;
    }

    if (_selectedGenres.isEmpty) {
      _showMessage("Please select at least one genre", isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final url = Uri.parse('http://10.0.2.2:8000/users/register/');

    String autoUsername = _emailController.text.split('@')[0];
    String bioValue = _bioController.text.isEmpty ? "-" : _bioController.text;
    String genreString = _selectedGenres.join(', ');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _emailController.text,
          'password': _passwordController.text,
          'username': autoUsername,
          'favorite_genres': genreString,
          'bio': bioValue,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showMessage(
          "Registration Successful! Please Sign in.",
          isError: false,
        );
        Navigator.pop(context);
      } else {
        var errorData = jsonDecode(response.body);
        String errMsg = errorData['detail'] ?? "Registration Failed";
        _showMessage("Failed: $errMsg", isError: true);
      }
    } catch (e) {
      print("Error: $e");
      _showMessage("Cannot connect to server", isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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
              const SizedBox(height: 20),

              _buildLabel('Email'),
              _buildTextField(_emailController, 'username@mail.com', false),

              const SizedBox(height: 15),

              _buildLabel('Password'),
              _buildTextField(
                _passwordController,
                '********',
                true,
                obscure: _obscurePassword,
                onToggle: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 6, left: 4),
                child: Text(
                  'อย่างน้อย 8 ตัว • มีพิมพ์ใหญ่-เล็ก • มีตัวเลข',
                  style: TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ),

              const SizedBox(height: 15),

              _buildLabel('Confirm Password'),
              _buildTextField(
                _confirmController,
                '********',
                true,
                obscure: _obscureConfirm,
                onToggle: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
              ),

              const SizedBox(height: 15),

              _buildLabel('Favorite Genres (Select multiple)'),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Wrap(
                  spacing: 8.0,
                  runSpacing: 4.0,
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
                        side: const BorderSide(color: Colors.transparent),
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

              const SizedBox(height: 30),

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
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.black,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Sign Up',
                          style: TextStyle(
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

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(color: Colors.white, fontSize: 16),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint,
    bool isPassword, {
    bool obscure = true,
    VoidCallback? onToggle,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: TextField(
        controller: controller,
        obscureText: isPassword ? obscure : false,
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
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    obscure ? Icons.visibility_off : Icons.visibility,
                    color: Colors.white54,
                    size: 20,
                  ),
                  onPressed: onToggle,
                )
              : null,
        ),
      ),
    );
  }
}
