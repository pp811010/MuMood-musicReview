import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class EditSongPage extends StatefulWidget {
  final Map songData;
  const EditSongPage({super.key, required this.songData});

  @override
  _EditSongPageState createState() => _EditSongPageState();
}

class _EditSongPageState extends State<EditSongPage> {
  final _formKey = GlobalKey<FormState>();

  // FocusNodes สำหรับคุม UI แบบเดียวกับหน้าเพิ่มเพลง
  final FocusNode _nameFocus = FocusNode();
  final FocusNode _artistFocus = FocusNode();
  final FocusNode _albumFocus = FocusNode();

  late TextEditingController _nameController;
  late TextEditingController _artistController;
  late TextEditingController _albumController;
  late TextEditingController _linkController;

  String? _selectedCategory;
  File? _newImageFile;
  bool _isProcessing = false;
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
    _nameController = TextEditingController(text: widget.songData['name']);
    _artistController = TextEditingController(text: widget.songData['artist']);
    _albumController = TextEditingController(
      text: widget.songData['album'] ?? "",
    );
    _linkController = TextEditingController(
      text: widget.songData['link_url'] ?? "",
    );

    if (widget.songData['is_custom'] == false) {
      _snapshotSpotifySong = widget.songData['name'];
      _snapshotSpotifyArtist = widget.songData['artist'];
    }

    final String? dbCategory = widget.songData['category']?.toString().trim();
    if (dbCategory != null) {
      try {
        _selectedCategory = _categories.firstWhere(
          (c) => c.toLowerCase() == dbCategory.toLowerCase(),
        );
      } catch (_) {
        _selectedCategory = _categories.first;
      }
    } else {
      _selectedCategory = _categories.first;
    }

    _nameFocus.addListener(() => setState(() {}));
    _artistFocus.addListener(() => setState(() {}));
    _albumFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameFocus.dispose();
    _artistFocus.dispose();
    _albumFocus.dispose();
    _nameController.dispose();
    _artistController.dispose();
    _albumController.dispose();
    super.dispose();
  }

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
      final res = await http.get(
        Uri.parse("http://10.0.2.2:8000/admin/search-metadata?query=$query"),
      );
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
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
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked != null) setState(() => _newImageFile = File(picked.path));
  }

  Future<void> _updateSong() async {
    if (!_formKey.currentState!.validate()) return;

    final currentSong = _nameController.text.trim().toLowerCase();
    final currentArtist = _artistController.text.trim().toLowerCase();

    // 1. ตรวจสอบกับ Snapshot (ค่าเดิมที่โหลดมาตอนแรก)
    bool isMatchSnapshot =
        _snapshotSpotifySong != null &&
        currentSong == _snapshotSpotifySong!.toLowerCase().trim() &&
        currentArtist == _snapshotSpotifyArtist!.toLowerCase().trim();

    // 2. ตรวจสอบกับรายการแนะนำ (กรณีผู้ใช้พิมพ์หาจนเจอใน Spotify)
    bool isMatchSuggestions = _songObjects.any(
      (item) =>
          item['name'].toString().toLowerCase().trim() == currentSong &&
          item['artist'].toString().toLowerCase().trim() == currentArtist,
    );

    if (isMatchSnapshot || isMatchSuggestions) {
      _showSnackBar(
        "เพลงนี้มีอยู่ใน Spotify แล้ว ไม่จำเป็นต้องแก้ไขให้ซ้ำซ้อน",
        Colors.orange,
      );
      return;
    }

    setState(() => _isProcessing = true);
    try {
      var request = http.MultipartRequest(
        "PATCH",
        Uri.parse("http://10.0.2.2:8000/songs/${widget.songData['id']}"),
      );
      request.fields['song_name'] = _nameController.text.trim();
      request.fields['category'] = _selectedCategory!;
      request.fields['artist_name'] = _artistController.text.trim();
      request.fields['album_name'] = _albumController.text.trim();
      request.fields['link_url'] = _linkController.text.trim();

      if (_newImageFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath('file', _newImageFile!.path),
        );
      }

      final streamedRes = await request.send();
      if (streamedRes.statusCode == 200)
        Navigator.pop(context, true);
      else {
        final res = await http.Response.fromStream(streamedRes);
        _showSnackBar("Error: ${json.decode(res.body)['detail']}", Colors.red);
      }
    } catch (e) {
      _showSnackBar("Update Error: $e", Colors.red);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _deleteSong() async {
    bool confirm = await _showConfirmDialog();
    if (!confirm) return;

    setState(() => _isProcessing = true);
    try {
      final res = await http.delete(
        Uri.parse("http://10.0.2.2:8000/songs/${widget.songData['id']}"),
      );
      if (res.statusCode == 200) Navigator.pop(context, true);
    } catch (e) {
      debugPrint("Delete Error: $e");
    } finally {
      if (mounted) setState(() => _isProcessing = false);
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
          "Edit Music Detail",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          if (widget.songData['is_custom'] == true)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.redAccent),
              onPressed: _isProcessing ? null : _deleteSong,
            ),
        ],
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
                _nameController,
                "Song Name",
                'song',
                _nameFocus,
              ),
              const SizedBox(height: 20),
              _buildLabel("Category"),
              _buildDropdown(),
              const SizedBox(height: 20),
              _buildLabel("Artist Name"),
              _buildAutocompleteField(
                _artistController,
                "Artist Name",
                'artist',
                _artistFocus,
              ),
              const SizedBox(height: 20),
              _buildLabel("Album Name (Optional)"),
              _buildAutocompleteField(
                _albumController,
                "Album Name",
                'album',
                _albumFocus,
                isOptional: true,
              ),
              const SizedBox(height: 20),
              _buildLabel("Song Link"),
              _buildTextField(
                _linkController,
                "Song Link URL",
                focusNode: FocusNode(),
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

  // --- UI Components (Theme-Matched) ---

  Widget _buildAutocompleteField(
    TextEditingController controller,
    String hint,
    String type,
    FocusNode focusNode, {
    bool isOptional = false,
  }) {
    return Column(
      children: [
        _buildTextField(
          controller,
          hint,
          focusNode: focusNode,
          isOptional: isOptional,
          onChanged: (val) {
            // เมื่อมีการพิมพ์ใหม่ ให้ล้าง Snapshot เพื่อให้ Validate เนื้อหาใหม่ได้ทันที
            if (type == 'song' || type == 'artist') {
              if (_snapshotSpotifySong != null ||
                  _snapshotSpotifyArtist != null) {
                setState(() {
                  _snapshotSpotifySong = null;
                  _snapshotSpotifyArtist = null;
                });
              }
            }
            _fetchMetadataSuggestions(val, type);
          },
        ),
        if (focusNode.hasFocus) _buildSuggestionsContainer(type),
      ],
    );
  }

  Widget _buildSuggestionsContainer(String type) {
    List<dynamic> suggestions = (type == 'song')
        ? _songObjects
        : (type == 'artist')
        ? _suggestedArtists
        : _suggestedAlbums;
    if (suggestions.isEmpty) return const SizedBox.shrink();

    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2C),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [const BoxShadow(color: Colors.black26, blurRadius: 10)],
      ),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: suggestions.length,
        itemBuilder: (context, index) {
          final item = suggestions[index];
          return ListTile(
            title: Text(
              type == 'song' ? item['display'] : item.toString(),
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
            onTap: () {
              setState(() {
                if (type == 'song') {
                  _nameController.text = item['name'];
                  _artistController.text = item['artist'];
                  _albumController.text = item['album'];
                  _snapshotSpotifySong = item['name'];
                  _snapshotSpotifyArtist = item['artist'];
                } else if (type == 'artist')
                  _artistController.text = item;
                else
                  _albumController.text = item;
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
            child: _newImageFile != null
                ? Image.file(_newImageFile!, fit: BoxFit.cover)
                : Image.network(widget.songData['image'], fit: BoxFit.cover),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController ctrl,
    String hint, {
    required FocusNode focusNode,
    Function(String)? onChanged,
    bool isOptional = false,
  }) {
    return TextFormField(
      controller: ctrl,
      focusNode: focusNode,
      onChanged: onChanged,
      style: const TextStyle(color: Colors.white),
      validator: (v) =>
          (!isOptional && (v == null || v.isEmpty)) ? "Required" : null,
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
      onChanged: (val) {
        // หากมีการพิมพ์ใหม่ ให้ถอนการเชื่อมโยง Snapshot เพื่อให้ Validate ใหม่ได้
        setState(() => _selectedCategory = val);
      },
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFF2C2C2C),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
      ),
      validator: (value) => value == null ? 'Please select a category' : null,
    );
  }

  Widget _buildSubmitButton() {
    final bool isCustom = widget.songData['is_custom'] == true;
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: (_isProcessing || !isCustom) ? null : _updateSong,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00D138),
          disabledBackgroundColor: Colors.grey.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: _isProcessing
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
                "Save Changes",
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

  Future<bool> _showConfirmDialog() async {
    return await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF1E1E1E),
            title: const Text(
              "Delete Song",
              style: TextStyle(color: Colors.white),
            ),
            content: const Text(
              "Are you sure you want to remove this custom song?",
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text(
                  "Cancel",
                  style: TextStyle(color: Colors.white),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text(
                  "Delete",
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }
}
