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
  List<dynamic> dbSongs = []; // เพลงที่อยู่ใน PostgreSQL
  List<dynamic> spotifySongs = []; // ผลการค้นหาใหม่จาก Spotify API
  bool isLoading = false;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final TextEditingController _searchController = TextEditingController();

  // กำหนด IP ของ Backend (10.0.2.2 สำหรับ Android Emulator)
  static const String baseUrl = "http://10.0.2.2:8000";

  @override
  void initState() {
    super.initState();
    loadSongsFromDb(); // โหลดเพลงจาก DB ทันทีเมื่อเข้าหน้า
  }

  // 1. ฟังก์ชันดึงเพลงทั้งหมดจาก DB (เรียกใช้ @router.get("/spotify/all-songs"))
  Future<void> loadSongsFromDb() async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(Uri.parse('$baseUrl/spotify/all-songs'));
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

  Future<void> fetchSongsFromSpotify(String query) async {
    // 1. ถ้าช่องค้นหาว่าง ให้รีเซ็ตกลับไปแสดงเพลงทั้งหมดจาก DB
    if (query.trim().isEmpty) {
      setState(() {
        spotifySongs = []; // ล้างผลการค้นหาจาก Spotify
      });
      await loadSongsFromDb(); // ดึงเพลงทั้งหมดกลับมาโชว์ใน Tab All/Custom
      return;
    }

    setState(() => isLoading = true);

    try {
      // 2. เรียก API ค้นหาแบบ Hybrid (DB + Spotify)
      final response = await http.get(
        Uri.parse('$baseUrl/songs/search?q=$query'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> searchResults = json.decode(
          response.body,
        )['results'];

        setState(() {
          // กรองเพลงที่ตรงตามคำค้นหามาแสดงผล
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

  void _togglePreview(String? url) async {
    if (url == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("No preview available")));
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
                  _buildMusicGrid(dbSongs, "All"), // เพลงทั้งหมดใน DB
                  _buildMusicGrid([
                    ...spotifySongs, // ผลการค้นหาใหม่จาก API
                    ...dbSongs
                        .where((s) => s['is_custom'] == false)
                        .toList(), // เพลง Spotify ใน DB
                  ], "Spotify"), // ผลการค้นหาใหม่
                  _buildMusicGrid(
                    dbSongs.where((s) => s['is_custom'] == true).toList(),
                    "Custom",
                  ), // เพลงที่เพิ่มเอง
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
      return Center(
        child: Text(
          "No songs found in $type",
          style: const TextStyle(color: Colors.white54),
        ),
      );
    }

    return GridView.builder(
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
          onTap: () => _togglePreview(song['preview_url']),
          child: _buildMusicCard(song),
        );
      },
    );
  }

  Widget _buildAddCustomMusicCard() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CreatemusicPage()),
        ).then((_) => loadSongsFromDb()); // Refresh เมื่อกลับมาจากหน้าเพิ่มเพลง
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
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(15),
              ),
              child: Image.network(
                finalImageUrl.isNotEmpty
                    ? finalImageUrl
                    : "https://via.placeholder.com/150",
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (context, error, stackTrace) => const Center(
                  child: Icon(
                    Icons.music_note,
                    size: 50,
                    color: Colors.white24,
                  ),
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
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  song['artist'] ?? "Unknown Artist",
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
                if (song['preview_url'] != null)
                  const Align(
                    alignment: Alignment.bottomRight,
                    child: Icon(
                      Icons.play_circle_fill,
                      color: Colors.green,
                      size: 24,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
