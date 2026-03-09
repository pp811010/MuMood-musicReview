import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:frontend/services/song_service.dart';
import 'package:frontend/widgets/song_form/song_category_dropdown.dart';
import 'package:frontend/widgets/song_form/song_cover_picker.dart';
import 'package:frontend/widgets/song_form/song_form_label.dart';
import 'package:frontend/widgets/song_form/song_form_text_field.dart';
import 'package:frontend/widgets/song_form/song_suggestions_container.dart';


class EditSongPage extends StatefulWidget {
  final Map songData;
  const EditSongPage({super.key, required this.songData});

  @override
  _EditSongPageState createState() => _EditSongPageState();
}

class _EditSongPageState extends State<EditSongPage> {
  final _formKey = GlobalKey<FormState>();

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
        _selectedCategory = SongCategoryDropdown.categories.firstWhere(
          (c) => c.toLowerCase() == dbCategory.toLowerCase(),
        );
      } catch (_) {
        _selectedCategory = SongCategoryDropdown.categories.first;
      }
    } else {
      _selectedCategory = SongCategoryDropdown.categories.first;
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

    final isMatchSnapshot =
        _snapshotSpotifySong != null &&
        currentSong == _snapshotSpotifySong!.toLowerCase().trim() &&
        currentArtist == _snapshotSpotifyArtist!.toLowerCase().trim();

    if (isMatchSnapshot) {
      _showSnackBar(
        "This song is already available on Spotify or Database, so no further editing is needed.",
        Colors.orange,
      );
      return;
    }

    setState(() => _isProcessing = true);
    final freshResult = await fetchMetadataSuggestions(
      _nameController.text.trim(),
    );
    setState(() => _isProcessing = false);

    final freshSongs = freshResult['songs'] as List<Map<String, dynamic>>;
    final isMatchDb = freshSongs.any(
      (item) =>
          item['name'].toString().toLowerCase().trim() == currentSong &&
          item['artist'].toString().toLowerCase().trim() == currentArtist,
    );

    if (isMatchDb) {
      _showSnackBar(
        "This song is already available on Spotify or Database, so no further editing is needed.",
        Colors.orange,
      );
      return;
    }

    setState(() => _isProcessing = true);

    final result = await updateSong(
      songId: widget.songData['id'],
      songName: _nameController.text.trim(),
      category: _selectedCategory!,
      artistName: _artistController.text.trim(),
      albumName: _albumController.text.trim(),
      linkUrl: _linkController.text.trim(),
      newImageFile: _newImageFile,
    );

    if (mounted) setState(() => _isProcessing = false);

    if (result.isSuccess) {
      Navigator.pop(context, true);
    } else {
      _showSnackBar("Error: ${result.errorMessage}", Colors.red);
    }
  }

  Future<void> _deleteSong() async {
    final confirmed = await _showConfirmDialog();
    if (!confirmed) return;

    setState(() => _isProcessing = true);

    final result = await deleteSong(widget.songData['id']);

    if (mounted) setState(() => _isProcessing = false);

    if (result.isSuccess) {
      Navigator.pop(context, true);
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
    final bool isCustom = widget.songData['is_custom'] == true;

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
          if (isCustom)
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
              SongCoverPicker(
                localFile: _newImageFile,
                networkImageUrl: widget.songData['image'],
                onTap: _pickImage,
              ),
              const SizedBox(height: 30),

              const SongFormLabel(text: "Song Name (Song - Artist)"),
              _buildAutocompleteField(
                _nameController,
                "Song Name",
                'song',
                _nameFocus,
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
                _artistController,
                "Artist Name",
                'artist',
                _artistFocus,
              ),

              const SizedBox(height: 20),
              const SongFormLabel(text: "Album Name (Optional)"),
              _buildAutocompleteField(
                _albumController,
                "Album Name",
                'album',
                _albumFocus,
                isOptional: true,
              ),

              const SizedBox(height: 20),
              const SongFormLabel(text: "Song Link"),
              SongFormTextField(
                controller: _linkController,
                hint: "Song Link URL",
                focusNode: FocusNode(),
                isOptional: true,
              ),

              const SizedBox(height: 40),
              _buildSubmitButton(isCustom),
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
          onChanged: (val) {
            if ((type == 'song' || type == 'artist') &&
                (_snapshotSpotifySong != null ||
                    _snapshotSpotifyArtist != null)) {
              setState(() {
                _snapshotSpotifySong = null;
                _snapshotSpotifyArtist = null;
              });
            }
            _fetchSuggestions(val, type);
          },
        ),
        if (focusNode.hasFocus)
          SongSuggestionsContainer(
            type: type,
            songObjects: _songObjects,
            suggestedArtists: _suggestedArtists,
            suggestedAlbums: _suggestedAlbums,
            onSongSelected: ({required name, required artist, required album}) {
              setState(() {
                _nameController.text = name;
                _artistController.text = artist;
                _albumController.text = album;
                _snapshotSpotifySong = name;
                _snapshotSpotifyArtist = artist;
              });
              _clearSuggestions();
            },
            onArtistSelected: (val) {
              setState(() => _artistController.text = val);
              _clearSuggestions();
            },
            onAlbumSelected: (val) {
              setState(() => _albumController.text = val);
              _clearSuggestions();
            },
          ),
      ],
    );
  }

  Widget _buildSubmitButton(bool isCustom) {
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