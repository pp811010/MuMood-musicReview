import 'package:flutter/material.dart';
import 'createmusic_page.dart';

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  _InventoryPageState createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  // --- Mock Data: รายการเพลงจำลอง ---
  //List<Map<String, dynamic>> songs = []; // empty state test
  List<Map<String, dynamic>> songs = [
    {
      "id": 1,
      "name": "ดอกกระเจียวบาน",
      "artist": "ก้อง ห้วยไร่",
      "image_url":
          "https://i.scdn.co/image/ab67616d0000b273760a365f57a6279f048d0877",
      "is_custom": false, // Spotify
      "emotions": {"funny": 12, "chat": 32},
    },
    {
      "id": 2,
      "name": "THE LOSER",
      "artist": "URBOYTJ",
      "image_url":
          "https://i.scdn.co/image/ab67616d0000b27341851e4a5d8f63567781b01a",
      "is_custom": true, // Custom (Admin Created)
      "emotions": {"funny": 15, "chat": 10},
    },
    {
      "id": 3,
      "name": "กลัวว่าฉันจะไม่เสียใจ",
      "artist": "PURPEACH",
      "image_url":
          "https://i.scdn.co/image/ab67616d0000b273d6f784e60a34b223075c3f30",
      "is_custom": false, // Spotify
      "emotions": {"funny": 5, "chat": 8},
    },
    {
      "id": 4,
      "name": "เพลงที่เพิ่งสร้าง",
      "artist": "ศิลปินใหม่",
      "image_url": "https://via.placeholder.com/150",
      "is_custom": true, // Custom
      "emotions": {"funny": 0, "chat": 0},
    },
  ];

  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFF121212), // พื้นหลัง Dark Theme
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            "Inventory",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(50),
            child: Align(
              alignment: Alignment.centerLeft, // จัดให้ชิดซ้ายตามรูป
              child: TabBar(
                isScrollable:
                    true, // ทำให้ Tab กว้างตามเนื้อหาและจัดวางได้สวยขึ้น
                dividerColor: Colors.transparent, // เอาเส้นขีดล่างยาวๆ ออก
                indicatorColor: Colors
                    .white, // หรือใช้ Color(0xFFFF5722) ถ้าต้องการเส้นใต้สีส้ม
                indicatorSize:
                    TabBarIndicatorSize.label, // เส้นใต้สั้นเท่าตัวอักษร
                labelColor: Colors.white, // สีเมื่อเลือก
                unselectedLabelColor: Colors.grey, // สีเมื่อไม่ได้เลือก
                labelStyle: const TextStyle(
                  fontSize: 20, // ขนาดใหญ่ตามรูป image_5a8a75.png
                  fontWeight: FontWeight.bold,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                ), // เว้นระยะจากขอบจอ
                tabAlignment: TabAlignment.start, // เริ่มต้นจากฝั่งซ้าย
                tabs: const [
                  Tab(text: "All"),
                  Tab(text: "Spotify"),
                  Tab(text: "Custom"),
                ],
              ),
            ),
          ),
        ),
        body: TabBarView(
          children: [
            _buildMusicGrid("All"),
            _buildMusicGrid("Spotify"),
            _buildMusicGrid("Custom"),
          ],
        ),
      ),
    );
  }

  // --- Widget: ตารางรายการเพลง (Grid) ---
  Widget _buildMusicGrid(String type) {
    // แก้ไข Type Casting ด้วย .cast<Map<String, dynamic>>() เพื่อป้องกัน Error
    List<Map<String, dynamic>> filteredSongs = songs
        .where((s) {
          if (type == "Spotify") return s['is_custom'] == false;
          if (type == "Custom") return s['is_custom'] == true;
          return true; // Tab "All" แสดงทั้งหมด
        })
        .toList()
        .cast<Map<String, dynamic>>();

    // --- ส่วนแสดง Empty State (ถ้าไม่มีเพลงในหมวดนั้น) ---
    if (filteredSongs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.library_music_outlined,
              size: 100,
              color: Colors.white.withOpacity(0.1),
            ),
            const SizedBox(height: 20),
            Text(
              "No songs found in $type",
              style: const TextStyle(color: Colors.white54, fontSize: 16),
            ),
            const SizedBox(height: 30),
            if (type != "Spotify")
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CreatemusicPage(),
                    ),
                  );
                },
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text("Create First Song"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00D138), // สีเขียวสว่าง
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
          ],
        ),
      );
    }

    // --- ส่วนแสดง Grid รายการเพลงปกติ ---
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
      ),
      // ถ้าไม่ใช่หน้า Spotify ให้บวกเพิ่ม 1 เพื่อโชว์ปุ่ม Add Card
      itemCount: filteredSongs.length + (type != "Spotify" ? 1 : 0),
      itemBuilder: (context, index) {
        // เงื่อนไขโชว์ปุ่ม Add New Song ในช่องแรก
        if (type != "Spotify" && index == 0) {
          return _buildAddCard();
        }

        // ส่งข้อมูลเพลงไปยัง _buildMusicCard (จัดการ index ให้ถูกต้อง)
        final song = filteredSongs[type != "Spotify" ? index - 1 : index];
        return _buildMusicCard(song);
      },
    );
  }

  // --- Widget: ปุ่มเพิ่มเพลงใหม่ (Add Card) ---
  Widget _buildAddCard() {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CreatemusicPage()),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: Color(0xFF7CF4DE), // สีเขียวมิ้นต์
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.add, color: Colors.white, size: 40),
          ),
          const SizedBox(height: 12),
          const Text(
            "Add New Song",
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // --- Widget: การ์ดแสดงข้อมูลเพลง (รับ Map<String, dynamic> song) ---
  Widget _buildMusicCard(Map<String, dynamic> song) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // รูปภาพ Cover
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(15),
                  ),
                  child: Image.network(
                    song['image_url'],
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey[800],
                      child: const Icon(
                        Icons.music_note,
                        color: Colors.white24,
                      ),
                    ),
                  ),
                ),
              ),
              // รายละเอียด
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text(
                        song['name'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    Center(
                      child: Text(
                        song['artist'],
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    const SizedBox(height: 6),
                    // แถบแสดงสถิติ (Emotion & Chat)
                    Row(
                      children: [
                        _buildEmotionStat(
                          iconData: Icons.emoji_emotions_outlined,
                          count: song['emotions']['funny'],
                          color: Colors.orangeAccent,
                        ),
                        const SizedBox(width: 10),
                        _buildEmotionStat(
                          iconData: Icons.chat_bubble_outline,
                          count: song['emotions']['chat'],
                          color: Colors.white38,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          // ปุ่มลบ: แสดงเฉพาะเพลงที่ Admin สร้างเอง (is_custom: true)
          if (song['is_custom'] == true)
            Positioned(
              top: 5,
              right: 5,
              child: GestureDetector(
                onTap: () => debugPrint("Delete song id: ${song['id']}"),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.delete_outline,
                    color: Colors.redAccent,
                    size: 18,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // --- Widget: แถบสถิติด้านล่าง Card (Emotion/Comment) ---
  Widget _buildEmotionStat({
    String? iconPath,
    IconData? iconData,
    required int count,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        iconPath != null
            ? Image.asset(iconPath, width: 14, height: 14)
            : Icon(iconData, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          count.toString(),
          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11),
        ),
      ],
    );
  }
}
