import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:frontend/services/song_service.dart';
import 'package:frontend/widgets/song_form/song_category_dropdown.dart';
import 'package:frontend/widgets/song_form/song_cover_picker.dart';
import 'package:frontend/widgets/song_form/song_form_label.dart';
import 'package:frontend/widgets/song_form/song_form_text_field.dart';
import 'package:frontend/widgets/song_form/song_suggestions_container.dart';

class CreatemusicPage extends StatefulWidget {
  const CreatemusicPage({super.key});

  @override
  _CreatemusicPageState createState() => _CreatemusicPageState();
}

class _CreatemusicPageState extends State<CreatemusicPage> {
  final _formKey = GlobalKey<FormState>();
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  final FocusNode _songFocusNode = FocusNode();
  final FocusNode _artistFocusNode = FocusNode();
  final FocusNode _albumFocusNode = FocusNode();

  final TextEditingController _songNameController = TextEditingController();
  final TextEditingController _artistNameController = TextEditingController();
  final TextEditingController _albumNameController = TextEditingController();
  final TextEditingController _linkController = TextEditingController();

  String? _selectedCategory;
  bool _isUploading = false;
  String? _snapshotSpotifySong;
  String? _snapshotSpotifyArtist;

  List<Map<String, dynamic>> _songObjects = [];
  List<String> _suggestedArtists = [];
  List<String> _suggestedAlbums = [];

  @override
  void initState() {
    super.initState();
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
    _linkController.dispose();
    super.dispose();
  }

  Future<void> _fetchSuggestions(String query, String type) async {
    if (query.trim().length < 2) {
      setState(() {
        if (type == 'song') _songObjects = [];
        if (type == 'artist') _suggestedArtists = [];
        if (type == 'album') _suggestedAlbums = [];
      });
      return;
    }
    final result = await fetchMetadataSuggestions(query);
    setState(() {
      _songObjects = result['songs'];
      _suggestedArtists = result['artists'];
      _suggestedAlbums = result['albums'];
    });
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

    // ป้องกันการโกง: เทียบกับ Snapshot Spotify (Case-Insensitive)
    final currentSong = _songNameController.text.trim().toLowerCase();
    final currentArtist = _artistNameController.text.trim().toLowerCase();
    final isMatchSpotify =
        _snapshotSpotifySong != null &&
        currentSong == _snapshotSpotifySong!.toLowerCase().trim() &&
        currentArtist == _snapshotSpotifyArtist!.toLowerCase().trim();

    if (isMatchSpotify) {
      _showSnackBar(
        "เพลงนี้มีอยู่ใน Spotify แล้ว ไม่จำเป็นต้องเพิ่มแบบ Custom",
        Colors.orange,
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

    final result = await createSong(
      songName: _songNameController.text.trim(),
      category: _selectedCategory!,
      artistName: _artistNameController.text.trim(),
      albumName: _albumNameController.text.trim(),
      linkUrl: _linkController.text.trim(),
      imageFile: _imageFile!,
    );

    if (mounted) setState(() => _isUploading = false);

    if (result.isSuccess) {
      _showSnackBar("Song created successfully!", Colors.green);
      Future.delayed(
        const Duration(seconds: 1),
        () { if (mounted) Navigator.pop(context, true); },
      );
    } else {
      _showSnackBar("Error: ${result.errorMessage}", Colors.red);
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

  void _clearSuggestions() {
    setState(() {
      _songObjects = [];
      _suggestedArtists = [];
      _suggestedAlbums = [];
    });
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
              SongCoverPicker(localFile: _imageFile, onTap: _pickImage),
              const SizedBox(height: 30),

              const SongFormLabel(text: "Song Name (Song - Artist)"),
              _buildAutocompleteField(
                _songNameController,
                "Enter Song Name",
                'song',
                _songFocusNode,
              ),

              const SizedBox(height: 20),
              const SongFormLabel(text: "Category"),
              SongCategoryDropdown(
                value: _selectedCategory,
                onChanged: (val) => setState(() => _selectedCategory = val),
              ),

              const SizedBox(height: 20),
              const SongFormLabel(text: "Artist Name"),
              _buildAutocompleteField(
                _artistNameController,
                "Search Artist",
                'artist',
                _artistFocusNode,
              ),

              const SizedBox(height: 20),
              const SongFormLabel(text: "Album Name (Optional)"),
              _buildAutocompleteField(
                _albumNameController,
                "Search Album",
                'album',
                _albumFocusNode,
                isOptional: true,
              ),

              const SizedBox(height: 20),
              const SongFormLabel(text: "Song Link (Spotify/YouTube URL)"),
              SongFormTextField(
                controller: _linkController,
                hint: "Enter link URL",
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

  Widget _buildAutocompleteField(
    TextEditingController controller,
    String hint,
    String type,
    FocusNode focusNode, {
    bool isOptional = false,
  }) {
    return Column(
      children: [
        SongFormTextField(
          controller: controller,
          hint: hint,
          focusNode: focusNode,
          isOptional: isOptional,
          onChanged: (val) => _fetchSuggestions(val, type),
        ),
        if (focusNode.hasFocus)
          SongSuggestionsContainer(
            type: type,
            songObjects: _songObjects,
            suggestedArtists: _suggestedArtists,
            suggestedAlbums: _suggestedAlbums,
            onSongSelected: ({required name, required artist, required album}) {
              setState(() {
                _songNameController.text = name;
                _artistNameController.text = artist;
                _albumNameController.text = album;
                _snapshotSpotifySong = name;
                _snapshotSpotifyArtist = artist;
              });
              _clearSuggestions();
            },
            onArtistSelected: (val) {
              setState(() => _artistNameController.text = val);
              _clearSuggestions();
            },
            onAlbumSelected: (val) {
              setState(() => _albumNameController.text = val);
              _clearSuggestions();
            },
          ),
      ],
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
}
