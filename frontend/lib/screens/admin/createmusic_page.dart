import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CreatemusicPage extends StatefulWidget {
  const CreatemusicPage({super.key});

  @override
  _CreatemusicPageState createState() => _CreatemusicPageState();
}

class _CreatemusicPageState extends State<CreatemusicPage> {
  // --- Form & State Variables ---
  final _formKey = GlobalKey<FormState>();
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  final TextEditingController _songNameController = TextEditingController();
  final TextEditingController _artistNameController = TextEditingController();
  final TextEditingController _albumNameController = TextEditingController();
  String? _selectedCategory;

  bool _isUploading = false;

  final List<String> _categories = [
    'Pop',
    'Rock',
    'Jazz',
    'Hip-Hop',
    'Classical',
    'R&B'
  ];

  // --- Logic: Pick Image ---
  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1080,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      _showSnackBar("Error picking image: $e", Colors.red);
    }
  }

  // --- Logic: API Submission ---
  Future<void> _createSong() async {
    // 1. Validation
    if (!_formKey.currentState!.validate()) return;
    if (_imageFile == null) {
      _showSnackBar("Please select a song cover image", Colors.orange);
      return;
    }
    if (_selectedCategory == null) {
      _showSnackBar("Please select a category", Colors.orange);
      return;
    }

    setState(() => _isUploading = true);

    try {
      // ปรับเปลี่ยน URL เป็น IP ของเครื่อง Server/Backend ของคุณ
      var uri = Uri.parse("http://10.0.2.2:8000/admin/songs/create");
      var request = http.MultipartRequest("POST", uri);

      // Add Text Fields
      request.fields['song_name'] = _songNameController.text.trim();
      request.fields['category'] = _selectedCategory!;
      request.fields['artist_name'] = _artistNameController.text.trim();
      request.fields['album_name'] = _albumNameController.text.trim();

      // Add Image File
      var stream = http.ByteStream(_imageFile!.openRead());
      var length = await _imageFile!.length();
      var multipartFile = http.MultipartFile(
        'file',
        stream,
        length,
        filename: _imageFile!.path.split('/').last,
      );
      request.files.add(multipartFile);

      var response = await request.send();
      var responseData = await response.stream.bytesToString();

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSnackBar("Song created successfully!", Colors.green);
        // หน่วงเวลาเล็กน้อยเพื่อให้ User เห็น Snackbar ก่อนย้อนกลับ
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) Navigator.pop(context);
        });
      } else {
        var errorMsg = json.decode(responseData)['detail'] ?? "Upload failed";
        _showSnackBar("Error: $errorMsg", Colors.red);
      }
    } catch (e) {
      _showSnackBar("Connection Error: $e", Colors.red);
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: TextButton.icon(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
          label: Text(""),
        ),
        title: const Text("Back",
            style: TextStyle(color: Colors.white, fontSize: 16)),
        titleSpacing: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const Text(
                "Create New Song",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              // --- Image Input Section ---
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2C2C2C),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white12,
                        width: _imageFile == null ? 1 : 0,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: _imageFile != null
                          ? Image.file(_imageFile!, fit: BoxFit.cover)
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.image_outlined,
                                    size: 80,
                                    color: Colors.white),
                                const SizedBox(height: 8),
                                Icon(Icons.add,
                                    size: 30,
                                    color: Colors.white),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // --- Song Name ---
              _buildLabel("Song Name"),
              _buildTextField(_songNameController, "Enter Song Name"),
              const SizedBox(height: 24),

              // --- Category ---
              _buildLabel("Category"),
              _buildDropdown(),
              const SizedBox(height: 24),

              // --- Artist Name (Artist Management) ---
              _buildLabel("Artist Name"),
              _buildSearchableTextField(
                  _artistNameController, "Search or Enter Artist Name"),
              const SizedBox(height: 24),

              // --- Album Name (Album Management) ---
              _buildLabel("Album Name"),
              _buildSearchableTextField(
                  _albumNameController, "Search or Enter Album Name"),
              const SizedBox(height: 40),

              // --- Submit Button ---
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isUploading ? null : _createSong,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00D138),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: _isUploading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Create New Song",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // --- UI Components Helpers ---

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(text,
          style: const TextStyle(color: Colors.white70, fontSize: 14)),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      validator: (value) =>
          (value == null || value.isEmpty) ? "This field is required" : null,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
        filled: true,
        fillColor: const Color(0xFF2C2C2C),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  // ระบบจัดการ Artist/Album (พิมพ์ค้นหาหรือสร้างใหม่ได้ในช่องเดียวกัน)
  Widget _buildSearchableTextField(
      TextEditingController controller, String hint) {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: controller,
            style: const TextStyle(color: Colors.white),
            validator: (value) => (value == null || value.isEmpty)
                ? "This field is required"
                : null,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
              filled: true,
              fillColor: const Color(0xFF2C2C2C),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
                borderSide: BorderSide.none,
              ),
              // สามารถเพิ่ม suffixIcon เพื่อทำ Autocomplete ได้ในอนาคต
              suffixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2C),
        borderRadius: BorderRadius.circular(25),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButtonFormField<String>(
          value: _selectedCategory,
          hint: const Text("Select Category",
              style: TextStyle(color: Colors.grey, fontSize: 14)),
          isExpanded: true,
          dropdownColor: const Color(0xFF2C2C2C),
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white70),
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(border: InputBorder.none),
          items: _categories.map((String val) {
            return DropdownMenuItem<String>(
              value: val,
              child: Text(val),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedCategory = value;
            });
          },
          validator: (value) => value == null ? "Please select a category" : null,
        ),
      ),
    );
  }
}