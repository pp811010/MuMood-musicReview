import 'package:flutter/material.dart';
import '../../models/music.dart';

class FavoritePage extends StatefulWidget {
  const FavoritePage({super.key});

  @override
  State<FavoritePage> createState() => _FavoritePageState();
}

class _FavoritePageState extends State<FavoritePage> {
  // Mock Data
  final List<Music> favoriteSongs = [
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
    Music(
      id: 3,
      title: "Loser",
      artist: "UrboyTJ",
      genre: "Indie",
      image: "https://i.ytimg.com/vi/UGB_Bsm5Unk/maxresdefault.jpg",
    ),
    Music(
      id: 4,
      title: "Loser",
      artist: "UrboyTJ",
      genre: "R&B",
      image:
          "https://upload.wikimedia.org/wikipedia/en/2/2a/Giveon_-_Heartbreak_Anniversary.png",
    ),
    Music(
      id: 5,
      title: "Loser",
      artist: "UrboyTJ",
      genre: "Pop",
      image: "https://i.ytimg.com/vi/yNNMKN9BUmU/maxresdefault.jpg",
    ),
    Music(
      id: 6,
      title: "Loser",
      artist: "UrboyTJ",
      genre: "R&B",
      image:
          "https://upload.wikimedia.org/wikipedia/en/5/52/Daniel_Caesar_Get_You.jpg",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          // --- Profile Header Section ---
          const SizedBox(height: 10),
          _buildProfileHeader(),

          // --- Section Title ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "FAVORITE SONG",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 5),
                Container(height: 1, color: Colors.grey[700]),
              ],
            ),
          ),

          // --- Grid View ---
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: GridView.builder(
                itemCount: favoriteSongs.length,
                physics: const BouncingScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 0.7,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemBuilder: (context, index) {
                  final song = favoriteSongs[index];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            image: DecorationImage(
                              image: NetworkImage(song.image),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Song Title with Heart Icon
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              song.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(
                            Icons.favorite,
                            color: Colors.redAccent, // Heart icon color
                            size: 14,
                          ),
                        ],
                      ),
                      // Artist Name
                      Text(
                        song.artist,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 11,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget Mini Profile Header (Name & Avatar)
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

  // AppBar
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
