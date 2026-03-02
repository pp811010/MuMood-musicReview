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
  final _formKey = GlobalKey<FormState>();
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  final TextEditingController _songNameController = TextEditingController();
  final TextEditingController _artistNameController = TextEditingController();
  final TextEditingController _albumNameController = TextEditingController();
  String? _selectedCategory;
  bool _isUploading = false;

  // รายการแนะนำ (Suggestions) สำหรับ Autocomplete
  List<String> _suggestedArtists = [];
  List<String> _suggestedAlbums = [];

  final List<String> _categories = ['Pop', 'Rock', 'Jazz', 'Hip-Hop', 'Classical', 'R&B'];

  // --- Logic: ดึงข้อมูลแนะนำจาก Backend ---
  Future<void> _fetchMetadataSuggestions(String query, bool isArtist) async {
    if (query.length < 2) {
      setState(() {
        isArtist ? _suggestedArtists = [] : _suggestedAlbums = [];
      });
      return;
    }

    try {
      final response = await http.get(
        Uri.parse("http://10.0.2.2:8000/admin/search-metadata?query=$query"),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          if (isArtist) {
            _suggestedArtists = List<String>.from(data['artists']);
          } else {
            _suggestedAlbums = List<String>.from(data['albums']);
          }
        });
      }
    } catch (e) {
      debugPrint("Suggestions error: $e");
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1080,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        setState(() => _imageFile = File(pickedFile.path));
      }
    } catch (e) {
      _showSnackBar("Error picking image: $e", Colors.red);
    }
  }

  Future<void> _createSong() async {
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
      var uri = Uri.parse("http://10.0.2.2:8000/admin/songs/create");
      var request = http.MultipartRequest("POST", uri);

      request.fields['song_name'] = _songNameController.text.trim();
      request.fields['category'] = _selectedCategory!;
      request.fields['artist_name'] = _artistNameController.text.trim();
      request.fields['album_name'] = _albumNameController.text.trim();

      var multipartFile = await http.MultipartFile.fromPath(
        'file', 
        _imageFile!.path
      );
      request.files.add(multipartFile);

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSnackBar("Song created successfully!", Colors.green);
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) Navigator.pop(context, true); // ส่งค่า true เพื่อบอกหน้าก่อนหน้าให้ Refresh
        });
      } else {
        var errorMsg = json.decode(response.body)['detail'] ?? "Upload failed";
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
      SnackBar(content: Text(message), backgroundColor: color, behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Create New Song", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImagePicker(),
              const SizedBox(height: 30),
              _buildLabel("Song Name"),
              _buildTextField(_songNameController, "Enter Song Name"),
              const SizedBox(height: 20),
              _buildLabel("Category"),
              _buildDropdown(),
              const SizedBox(height: 20),
              _buildLabel("Artist Name"),
              _buildAutocompleteField(_artistNameController, "Search Artist", true),
              const SizedBox(height: 20),
              _buildLabel("Album Name"),
              _buildAutocompleteField(_albumNameController, "Search Album", false),
              const SizedBox(height: 40),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  // --- UI Helpers ---

  Widget _buildImagePicker() {
    return Center(
      child: GestureDetector(
        onTap: _pickImage,
        child: Container(
          width: 160, height: 160,
          decoration: BoxDecoration(
            color: const Color(0xFF2C2C2C),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white12),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: _imageFile != null
                ? Image.file(_imageFile!, fit: BoxFit.cover)
                : const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [Icon(Icons.image_outlined, size: 50, color: Colors.white54), Text("Add Cover", style: TextStyle(color: Colors.white54))],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildAutocompleteField(TextEditingController controller, String hint, bool isArtist) {
    return Column(
      children: [
        _buildTextField(controller, hint, onChanged: (val) => _fetchMetadataSuggestions(val, isArtist)),
        if (isArtist ? _suggestedArtists.isNotEmpty : _suggestedAlbums.isNotEmpty)
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(color: const Color(0xFF2C2C2C), borderRadius: BorderRadius.circular(15)),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: isArtist ? _suggestedArtists.length : _suggestedAlbums.length,
              itemBuilder: (context, index) {
                final label = isArtist ? _suggestedArtists[index] : _suggestedAlbums[index];
                return ListTile(
                  title: Text(label, style: const TextStyle(color: Colors.white)),
                  onTap: () {
                    setState(() {
                      controller.text = label;
                      isArtist ? _suggestedArtists = [] : _suggestedAlbums = [];
                    });
                  },
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, {Function(String)? onChanged}) {
    return TextFormField(
      controller: controller,
      onChanged: onChanged,
      style: const TextStyle(color: Colors.white),
      validator: (val) => (val == null || val.isEmpty) ? "Required" : null,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white24),
        filled: true, fillColor: const Color(0xFF2C2C2C),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedCategory,
      dropdownColor: const Color(0xFF2C2C2C),
      items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(color: Colors.white)))).toList(),
      onChanged: (val) => setState(() => _selectedCategory = val),
      decoration: InputDecoration(
        filled: true, fillColor: const Color(0xFF2C2C2C),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity, height: 55,
      child: ElevatedButton(
        onPressed: _isUploading ? null : _createSong,
        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00D138), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
        child: _isUploading ? const CircularProgressIndicator(color: Colors.white) : const Text("Create Song", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildLabel(String text) => Padding(padding: const EdgeInsets.only(left: 8, bottom: 8), child: Text(text, style: const TextStyle(color: Colors.white70)));
}