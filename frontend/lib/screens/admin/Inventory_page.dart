import 'package:flutter/material.dart';
import 'package:frontend/services/song_service.dart';
import 'package:frontend/widgets/song_form/add_music_card.dart';
import 'package:frontend/widgets/song_form/music_card.dart';
import 'createmusic_page.dart';
import 'edit_song_page.dart';

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  _InventoryPageState createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  List<dynamic> dbSongs = [];
  List<dynamic> spotifySongs = [];
  bool isLoading = false;
  final TextEditingController _searchController = TextEditingController();

  static const String baseUrl = "http://10.0.2.2:8000";

  @override
  void initState() {
    super.initState();
    _loadFromDb();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFromDb() async {
    setState(() => isLoading = true);
    final results = await loadAllSongs();
    setState(() {
      dbSongs = results;
      spotifySongs = [];
      isLoading = false;
    });
  }

  Future<void> _onSearch(String query) async {
    if (query.trim().isEmpty) {
      await _loadFromDb();
      return;
    }
    setState(() => isLoading = true);
    final results = await searchSongs(query);
    setState(() {
      dbSongs = results['db']!;
      spotifySongs = results['spotify']!;
      isLoading = false;
    });
  }

  Future<void> _onRefresh() async {
    final query = _searchController.text.trim();
    query.isNotEmpty ? await _onSearch(query) : await _loadFromDb();
  }

  Future<void> _deleteSongQuickly(int songId) async {
    final confirm = await _showConfirmDialog(
      "Delete Song",
      "Are you sure you want to remove this song?",
    );
    if (!confirm) return;

    setState(() => isLoading = true);
    final result = await deleteSong(songId);
    setState(() => isLoading = false);

    if (result.isSuccess) {
      _showSnackBar("Song deleted", Colors.green);
      _loadFromDb();
    } else {
      _showSnackBar("Error deleting song", Colors.red);
    }
  }

  Future<bool> _showConfirmDialog(String title, String message) async {
    return await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF1E1E1E),
            title: Text(title, style: const TextStyle(color: Colors.white)),
            content: Text(
              message,
              style: const TextStyle(color: Colors.white70),
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
                  style: TextStyle(color: Colors.redAccent),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFF121212),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: Container(
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(20),
            ),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: "Search music...",
                hintStyle: TextStyle(color: Colors.white38),
                prefixIcon: Icon(Icons.search, color: Colors.white38),
                border: InputBorder.none,
              ),
              onSubmitted: _onSearch,
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(50),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                dividerColor: Colors.transparent,
                indicatorColor: Colors.green,
                indicatorWeight: 3,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white38,
                labelStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                tabs: const [
                  Tab(text: "All"),
                  Tab(text: "Spotify"),
                  Tab(text: "Custom"),
                ],
              ),
            ),
          ),
        ),
        body: isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.green),
              )
            : TabBarView(
                children: [
                  _buildMusicGrid(dbSongs, "All"),
                  _buildMusicGrid([
                    ...spotifySongs,
                    ...dbSongs.where((s) => s['is_custom'] == false).toList(),
                  ], "Spotify"),
                  _buildMusicGrid(
                    dbSongs.where((s) => s['is_custom'] == true).toList(),
                    "Custom",
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildMusicGrid(List<dynamic> songs, String type) {
    final bool showAddButton = type == "All" || type == "Custom";
    final int itemCount = showAddButton ? songs.length + 1 : songs.length;

    if (songs.isEmpty && !showAddButton) {
      return RefreshIndicator(
        onRefresh: _onRefresh,
        color: Colors.green,
        backgroundColor: const Color(0xFF1E1E1E),
        child: ListView(
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.6,
              child: Center(
                child: Text(
                  "No songs found in $type",
                  style: const TextStyle(color: Colors.white54),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: Colors.green,
      backgroundColor: const Color(0xFF1E1E1E),
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,
        ),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          if (showAddButton && index == 0) {
            return AddMusicCard(
              onTap: () async {
                final updated = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CreatemusicPage(),
                  ),
                );
                if (updated == true) _loadFromDb();
              },
            );
          }

          final songIndex = showAddButton ? index - 1 : index;
          final song = songs[songIndex] as Map<String, dynamic>;

          return GestureDetector(
            onTap: () async {
              final updated = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditSongPage(songData: song),
                ),
              );
              if (updated == true) _loadFromDb();
            },
            child: MusicCard(
              song: song,
              baseUrl: baseUrl,
              onDelete: () => _deleteSongQuickly(song['id']),
            ),
          );
        },
      ),
    );
  }
}
