import 'package:flutter/material.dart';
import '../../models/music.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock Data
    final List<Music> historySongs = [
      Music(
        id: 1,
        title: "Loser",
        artist: "UrboyTJ",
        genre: "Pop",
        image: "https://i.ytimg.com/vi/yNNMKN9BUmU/maxresdefault.jpg",
      ),
      Music(
        id: 2,
        title: "Loser",
        artist: "UrboyTJ",
        genre: "R&B",
        image:
            "https://upload.wikimedia.org/wikipedia/en/5/52/Daniel_Caesar_Get_You.jpg",
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          const SizedBox(height: 10),
          _buildProfileHeader(),

          // --- Section Title ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "History (10)",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Container(height: 1, color: Colors.grey[700]),
              ],
            ),
          ),

          // --- List View ---
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: historySongs.length,
              itemBuilder: (context, index) {
                final song = historySongs[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2C2C2C),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Cover Image
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          song.image,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              song.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "${song.artist}",
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Stats (Mock Data)
                            const Text(
                              "BEAT 3.5  LYRIC 3.5  MOOD 3.5",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Description
                            const Text(
                              "I'm not a huge Thailand fan, but I've listen to TJ and loved them.",
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 11,
                                height: 1.4,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Reused Components (Maybe move to separate widget file later)
  Widget _buildProfileHeader() {
    return Row(
      children: [
        const SizedBox(width: 24),
        Container(
          padding: const EdgeInsets.all(3),
          decoration: const BoxDecoration(
            color: Color(0xFFFFCCBC),
            shape: BoxShape.circle,
          ),
          child: const CircleAvatar(
            radius: 32,
            backgroundColor: Colors.transparent,
            backgroundImage: AssetImage("assets/icons/funny_emoji.png"),
          ),
        ),
        const SizedBox(width: 20),
        const Text(
          "Peter",
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leadingWidth: 80,
      leading: TextButton.icon(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 16),
        label: const Text(
          "Back",
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        style: TextButton.styleFrom(padding: const EdgeInsets.only(left: 10)),
      ),
      actions: [
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.login_outlined, color: Colors.white),
        ),
      ],
    );
  }
}
