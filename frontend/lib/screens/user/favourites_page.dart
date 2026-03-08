import 'package:flutter/material.dart';
import '../../core/api_client.dart';
import '../../services/favorite_service.dart';
import '../../services/user_service.dart';
import '../../widgets/profile_header.dart';
import '../../widgets/page_state_handler.dart';
import '../../widgets/section_header.dart';
import '../user/song_detail.dart';

class FavoritePage extends StatefulWidget {
  const FavoritePage({super.key});

  @override
  State<FavoritePage> createState() => _FavoritePageState();
}

class _FavoritePageState extends State<FavoritePage> {
  List<Map<String, dynamic>> _favoriteSongs = [];
  Map<String, dynamic>? _profile;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
    dataRefreshNotifier.addListener(_onDataChanged);
  }

  @override
  void dispose() {
    dataRefreshNotifier.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
    if (mounted) _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        ApiService.getProfile(),
        fetchMyFavorites(),
      ]);

      if (!mounted) return;
      setState(() {
        _profile = results[0] as Map<String, dynamic>;
        _favoriteSongs = (results[1] as List).cast<Map<String, dynamic>>();
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _onRetry() {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: PageStateHandler(
        isLoading: _isLoading,
        errorMessage: _errorMessage,
        onRetry: _onRetry,
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        const SizedBox(height: 10),
        ProfileHeader(username: _profile?['username'] ?? ''),
        SectionHeader(title: 'FAVORITE SONG (${_favoriteSongs.length})'),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadData,
            color: Colors.redAccent,
            backgroundColor: Colors.grey[900],
            child: _favoriteSongs.isEmpty
                ? _buildEmptyState()
                : _buildSongGrid(),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.5,
          child: const Center(
            child: Text(
              'ยังไม่มีเพลงโปรด',
              style: TextStyle(color: Colors.white54),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSongGrid() {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: _favoriteSongs.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.7,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemBuilder: (context, index) => _buildSongTile(_favoriteSongs[index]),
    );
  }

  Widget _buildSongTile(Map<String, dynamic> song) {
    final coverUrl = song['song_cover_url'] as String?;
    final songName = song['song_name'] ?? 'Unknown';
    final artistName = song['artist_name'] ?? '';
    final songId = (song['song_id'] ?? song['id']).toString();

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => MusicDetail(id: songId)),
        );
        _loadData();
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _buildCoverImage(coverUrl)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  songName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(Icons.favorite, color: Colors.redAccent, size: 14),
            ],
          ),
          Text(
            artistName,
            style: const TextStyle(color: Colors.grey, fontSize: 11),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildCoverImage(String? coverUrl) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey[800],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: coverUrl != null && coverUrl.isNotEmpty
            ? Image.network(
                coverUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _coverPlaceholder(),
              )
            : _coverPlaceholder(),
      ),
    );
  }

  Widget _coverPlaceholder() {
    return const Icon(Icons.music_note, color: Colors.white54, size: 32);
  }
}
