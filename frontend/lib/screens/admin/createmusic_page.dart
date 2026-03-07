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

  // FocusNodes สำหรับควบคุมการแสดงผล Suggestion ตามการเลือกช่อง
  final FocusNode _songFocusNode = FocusNode();
  final FocusNode _artistFocusNode = FocusNode();
  final FocusNode _albumFocusNode = FocusNode();

  final TextEditingController _songNameController = TextEditingController();
  final TextEditingController _artistNameController = TextEditingController();
  final TextEditingController _albumNameController = TextEditingController();

  String? _selectedCategory;
  bool _isUploading = false;
  bool _isFromSpotify = false;
  String? _snapshotSpotifySong;
  String? _snapshotSpotifyArtist;

  List<Map<String, dynamic>> _songObjects = [];
  List<String> _suggestedArtists = [];
  List<String> _suggestedAlbums = [];

  final List<String> _categories = [
    'Pop',
    'Rock',
    'Jazz',
    'Hip-Hop',
    'Classical',
    'R&B',
    'K-Pop',
    'Indie',
    'Metal',
    'EDM',
  ];

  @override
  void initState() {
    super.initState();
    // สั่ง Rebuild เมื่อ Focus เปลี่ยนเพื่อซ่อน/แสดง Suggestion List
    _songFocusNode.addListener(() => setState(() {}));
    _artistFocusNode.addListener(() => setState(() {}));
    _albumFocusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _songFocusNode.dispose();
    _artistFocusNode.dispose();
    _albumFocusNode.dispose();
    _songNameController.dispose();
    _artistNameController.dispose();
    _albumNameController.dispose();
    super.dispose();
  }

  // --- Logic: Search Metadata (Hybrid DB + Spotify) ---
  Future<void> _fetchMetadataSuggestions(String query, String type) async {
    if (query.trim().length < 2) {
      setState(() {
        if (type == 'song') _songObjects = [];
        if (type == 'artist') _suggestedArtists = [];
        if (type == 'album') _suggestedAlbums = [];
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
          _songObjects = List<Map<String, dynamic>>.from(data['songs'] ?? []);
          _suggestedArtists = List<String>.from(data['artists'] ?? []);
          _suggestedAlbums = List<String>.from(data['albums'] ?? []);
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

  // --- Logic: Create Song with Double Validation ---
  Future<void> _createSong() async {
    if (!_formKey.currentState!.validate()) return;

    // ✅ ป้องกันการโกง: เทียบเนื้อหาจริง (Case-Insensitive) กับค่า Snapshot ดั้งเดิม
    // ไม่ว่าผู้ใช้จะแก้แล้วแก้กลับ หรือเปลี่ยนตัวพิมพ์ ระบบจะตรวจเจอเสมอ
    final currentSong = _songNameController.text.trim().toLowerCase();
    final currentArtist = _artistNameController.text.trim().toLowerCase();

    bool isMatchSpotify = _snapshotSpotifySong != null && 
        currentSong == _snapshotSpotifySong!.toLowerCase().trim() &&
        currentArtist == _snapshotSpotifyArtist!.toLowerCase().trim();

    if (isMatchSpotify) {
      _showSnackBar(
        "เพลงนี้มีอยู่ใน Spotify แล้ว ไม่จำเป็นต้องเพิ่มแบบ Custom", 
        Colors.orange
      );
      return;
    }

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

      request.files.add(await http.MultipartFile.fromPath('file', _imageFile!.path));

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSnackBar("Song created successfully!", Colors.green);
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) Navigator.pop(context, true);
        });
      } else {
        // ✅ ระบบตรวจสอบด่านสุดท้ายจาก Database
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Create New Song",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
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

              _buildLabel("Song Name (Song - Artist)"),
              _buildAutocompleteField(
                _songNameController,
                "Enter Song Name",
                'song',
                _songFocusNode,
              ),

              const SizedBox(height: 20),
              _buildLabel("Category"),
              _buildDropdown(),

              const SizedBox(height: 20),
              _buildLabel("Artist Name"),
              _buildAutocompleteField(
                _artistNameController,
                "Search Artist",
                'artist',
                _artistFocusNode,
              ),

              const SizedBox(height: 20),
              _buildLabel("Album Name (Optional)"),
              _buildAutocompleteField(
                _albumNameController,
                "Search Album",
                'album',
                _albumFocusNode,
                isOptional: true,
              ),

              const SizedBox(height: 40),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  // --- UI Components ---

  Widget _buildAutocompleteField(TextEditingController controller, String hint, String type, FocusNode focusNode, {bool isOptional = false}) {
    return Column(
      children: [
        _buildTextField(
          controller, 
          hint, 
          focusNode: focusNode,
          isOptional: isOptional,
          onChanged: (val) {
            // เราไม่ลบ Snapshot ที่นี่ เพื่อให้ _createSong ตรวจสอบความถูกต้องของเนื้อหาได้เสมอ
            _fetchMetadataSuggestions(val, type);
          }
        ),
        if (focusNode.hasFocus) _buildSuggestionsContainer(type),
      ],
    );
  }

  Widget _buildSuggestionsContainer(String type) {
    List<dynamic> suggestions;
    if (type == 'song') suggestions = _songObjects;
    else if (type == 'artist') suggestions = _suggestedArtists;
    else suggestions = _suggestedAlbums;

    if (suggestions.isEmpty) return const SizedBox.shrink();

    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2C), 
        borderRadius: BorderRadius.circular(15),
        boxShadow: [const BoxShadow(color: Colors.black26, blurRadius: 10)]
      ),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: suggestions.length,
        itemBuilder: (context, index) {
          final item = suggestions[index];
          final String displayLabel = type == 'song' ? item['display'] : item.toString();
          
          return ListTile(
            title: Text(displayLabel, style: const TextStyle(color: Colors.white, fontSize: 14)),
            onTap: () {
              setState(() {
                if (type == 'song') {
                  _songNameController.text = item['name'];
                  _artistNameController.text = item['artist'];
                  _albumNameController.text = item['album'];
                  
                  _snapshotSpotifySong = item['name'];
                  _snapshotSpotifyArtist = item['artist'];
                } else if (type == 'artist') {
                  _artistNameController.text = item;
                } else {
                  _albumNameController.text = item;
                }
                _songObjects = [];
                _suggestedArtists = [];
                _suggestedAlbums = [];
              });
              FocusScope.of(context).unfocus();
            },
          );
        },
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint, {
    required FocusNode focusNode,
    Function(String)? onChanged,
    bool isOptional = false,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      onChanged: onChanged,
      style: const TextStyle(color: Colors.white),
      validator: (val) {
        if (isOptional) return null;
        return (val == null || val.isEmpty) ? "*Required" : null;
      },
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white24),
        filled: true,
        fillColor: const Color(0xFF2C2C2C),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return Center(
      child: GestureDetector(
        onTap: _pickImage,
        child: Container(
          width: 160,
          height: 160,
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
                    children: [
                      Icon(
                        Icons.image_outlined,
                        size: 50,
                        color: Colors.white54,
                      ),
                      Text(
                        "Add Cover",
                        style: TextStyle(color: Colors.white54),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedCategory,
      dropdownColor: const Color(0xFF2C2C2C),
      hint: const Text(
        "Select Category",
        style: TextStyle(color: Colors.white24),
      ),
      items: _categories
          .map(
            (c) => DropdownMenuItem(
              value: c,
              child: Text(c, style: const TextStyle(color: Colors.white)),
            ),
          )
          .toList(),
      onChanged: (val) => setState(() => _selectedCategory = val),
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFF2C2C2C),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
      ),
      validator: (value) => value == null ? '*Please select a category' : null,
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
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
                "Create Song",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Widget _buildLabel(String text) => Padding(
    padding: const EdgeInsets.only(left: 8, bottom: 8),
    child: Text(text, style: const TextStyle(color: Colors.white70)),
  );
}
