import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'dart:convert';
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
  final AudioPlayer _audioPlayer = AudioPlayer();
  final TextEditingController _searchController = TextEditingController();
  static const String baseUrl = "http://10.0.2.2:8000";

  @override
  void initState() {
    super.initState();
    loadSongsFromDb();
  }

  Future<void> loadSongsFromDb() async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(Uri.parse('$baseUrl/songs/db/all-songs'));
      if (response.statusCode == 200) {
        setState(() {
          dbSongs = json.decode(response.body)['results'];
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() => isLoading = false);
      debugPrint("Error loading from DB: $e");
    }
  }

  Future<void> _onRefresh() async {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      await fetchSongsFromSpotify(query);
    } else {
      await loadSongsFromDb();
    }
  }

  Future<void> fetchSongsFromSpotify(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        spotifySongs = [];
      });
      await loadSongsFromDb();
      return;
    }

    setState(() => isLoading = true);

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/songs/search?q=$query'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> searchResults = json.decode(
          response.body,
        )['results'];

        setState(() {
          dbSongs = searchResults.where((s) => s['source'] == 'db').toList();
          spotifySongs = searchResults
              .where((s) => s['source'] == 'spotify')
              .toList();
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() => isLoading = false);
      debugPrint("Search error: $e");
    }
  }

  Future<void> _deleteSongQuickly(int songId) async {
    bool confirm = await _showConfirmDialog(
      "Delete Song",
      "Are you sure you want to remove this song?",
    );
    if (!confirm) return;

    setState(() => isLoading = true);
    try {
      final response = await http.delete(Uri.parse('$baseUrl/songs/$songId'));
      if (response.statusCode == 200) {
        loadSongsFromDb();
        _showSnackBar("Song deleted", Colors.green);
      }
    } catch (e) {
      _showSnackBar("Error deleting song", Colors.red);
    } finally {
      setState(() => isLoading = false);
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
                child: const Text("Cancel", style: TextStyle(color: Colors.white)),
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _searchController.dispose();
    super.dispose();
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
              onSubmitted: (value) => fetchSongsFromSpotify(value),
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
                    ...dbSongs
                        .where((s) => s['is_custom'] == false)
                        .toList(),
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

  Widget _buildMusicGrid(List<dynamic> displaySongs, String type) {
    bool showAddButton = (type == "All" || type == "Custom");
    int itemCount = showAddButton
        ? displaySongs.length + 1
        : displaySongs.length;

    if (displaySongs.isEmpty && !showAddButton) {
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
          if (showAddButton && index == 0) return _buildAddCustomMusicCard();

          final songIndex = showAddButton ? index - 1 : index;
          final song = displaySongs[songIndex];

          return GestureDetector(
            onTap: () async {
              bool? updated = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditSongPage(songData: song),
                ),
              );

              if (updated == true) {
                loadSongsFromDb();
              }
            },
            child: _buildMusicCard(song),
          );
        },
      ),
    );
  }

  Widget _buildAddCustomMusicCard() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CreatemusicPage()),
        ).then((_) => loadSongsFromDb());
      },
      child: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(15)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: Color(0xFF4DB6AC),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 50),
            ),
            const SizedBox(height: 15),
            const Text(
              "Add New Song",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMusicCard(Map<String, dynamic> song) {
    String rawImageUrl = song['image'] ?? "";
    String finalImageUrl = "";
    if (rawImageUrl.startsWith("http")) {
      finalImageUrl = rawImageUrl;
    } else if (rawImageUrl.startsWith("/static")) {
      finalImageUrl = "$baseUrl$rawImageUrl";
    } else if (rawImageUrl.isNotEmpty) {
      finalImageUrl = "$baseUrl/$rawImageUrl";
    }

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                  child: Image.network(
                    finalImageUrl.isNotEmpty ? finalImageUrl : "https://via.placeholder.com/150",
                    fit: BoxFit.cover, width: double.infinity,
                    errorBuilder: (context, error, stackTrace) => const Center(
                      child: Icon(Icons.music_note, size: 50, color: Colors.white24),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      song['name'] ?? "Unknown",
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      song['artist'] ?? "Unknown Artist",
                      style: const TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        if (song['is_custom'] == true)
          Positioned(
            top: 5,
            right: 5,
            child: GestureDetector(
              onTap: () => _deleteSongQuickly(song['id']),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
              ),
            ),
          ),
      ],
    );
  }
}