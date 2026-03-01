import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'dart:convert';
import 'createmusic_page.dart';

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  _InventoryPageState createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  List<dynamic> songs = []; 
  bool isLoading = false;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final TextEditingController _searchController = TextEditingController();

  // ฟังก์ชันดึงข้อมูลจาก FastAPI
  Future<void> fetchSongs(String query) async {
    if (query.isEmpty) return;
    
    setState(() => isLoading = true);
    try {
      // เปลี่ยน IP เป็นเลขเครื่องคอมพิวเตอร์ของคุณ (ถ้าใช้ Android Emulator ให้ใช้ 10.0.2.2)
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8000/spotify/search?q=$query'),
      );

      if (response.statusCode == 200) {
        setState(() {
          songs = json.decode(response.body)['results'];
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() => isLoading = false);
      debugPrint("Error fetching songs: $e");
    }
  }

  // ฟังก์ชันเล่นเพลง Preview
  void _togglePreview(String? url) async {
    if (url == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No preview available for this song")),
      );
      return;
    }
    await _audioPlayer.play(UrlSource(url));
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
                hintText: "Search music by mood...",
                hintStyle: TextStyle(color: Colors.white38),
                prefixIcon: Icon(Icons.search, color: Colors.white38),
                border: InputBorder.none,
              ),
              onSubmitted: (value) => fetchSongs(value), // กด Enter เพื่อค้นหา
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(50),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TabBar(
                isScrollable: true,
                dividerColor: Colors.transparent,
                indicatorColor: Colors.white,
                indicatorSize: TabBarIndicatorSize.label,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.grey,
                labelStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : TabBarView(
              children: [
                _buildMusicGrid("All"),
                _buildMusicGrid("Spotify"),
                _buildMusicGrid("Custom"),
              ],
            ),
      ),
    );
  }

  Widget _buildMusicGrid(String type) {
    // กรองเพลงตามประเภท (ในที่นี้ข้อมูลจาก Spotify จะไม่มี is_custom)
    List<dynamic> filteredSongs = songs.where((s) {
      if (type == "Spotify") return s['preview_url'] != null; // ตรวจสอบว่าเป็นเพลงจาก Spotify
      if (type == "Custom") return s['is_custom'] == true;
      return true;
    }).toList();

    if (filteredSongs.isEmpty) {
      return _buildEmptyState(type);
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
      ),
      itemCount: filteredSongs.length,
      itemBuilder: (context, index) {
        final song = filteredSongs[index];
        return GestureDetector(
          onTap: () => _togglePreview(song['preview_url']), // กดแล้วเล่นเพลง
          child: _buildMusicCard(song),
        );
      },
    );
  }

  // --- ปรับปรุง Card ให้รับข้อมูลจาก API ---
  Widget _buildMusicCard(Map<String, dynamic> song) {
    return Container(
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
                song['image'] ?? "https://via.placeholder.com/150", // ใช้ Key 'image' จาก FastAPI
                fit: BoxFit.cover,
                width: double.infinity,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Text(
                  song['name'] ?? "Unknown",
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  song['artist'] ?? "Unknown Artist",
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
                const SizedBox(height: 4),
                // แสดง Icon Play ถ้ามี preview_url
                if (song['preview_url'] != null)
                  const Icon(Icons.play_circle_fill, color: Colors.green, size: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String type) {
     return Center(child: Text("Search for music to see results", style: TextStyle(color: Colors.white54)));
  }
}
