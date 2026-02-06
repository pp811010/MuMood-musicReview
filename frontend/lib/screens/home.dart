import 'package:flutter/material.dart';
import 'package:frontend/models/music.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final _searchController = TextEditingController();
  String _selectedGenre = 'All';
  

  final List<Music> allMusic = [
    Music(
      id: 1,
      title: "Like I Want You",
      artist: "GIVĒON",
      genre: "Pop",
      image: "https://i.ytimg.com/vi/yNNMKN9BUmU/maxresdefault.jpg",
    ),
    Music(
      id: 2,
      title: "Got you",
      artist: "daniel caesar",
      genre: "R&B",
      image:
          "https://upload.wikimedia.org/wikipedia/en/5/52/Daniel_Caesar_Get_You.jpg",
    ),
    Music(
      id: 3,
      title: "heartbreak",
      artist: "GIVĒON",
      genre: "Jass",
      image:
          "https://upload.wikimedia.org/wikipedia/en/2/2a/Giveon_-_Heartbreak_Anniversary.png",
    ),
    Music(
      id: 4,
      title: "ew",
      artist: "joji",
      genre: "Indie",
      image: "https://i.ytimg.com/vi/UGB_Bsm5Unk/maxresdefault.jpg",
    ),
    Music(
      id: 5,
      title: "heartbreak",
      artist: "GIVĒON",
      genre: "Pop",
      image:
          "https://upload.wikimedia.org/wikipedia/en/2/2a/Giveon_-_Heartbreak_Anniversary.png",
    ),
    Music(
      id: 6,
      title: "count me out",
      artist: "kendrick lamar ",
      genre: "Hip Hop",
      image:
          "https://images.genius.com/e114b4b3a183aa12358c68f619dddb7e.1000x563x1.jpg",
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isSearching = _searchController.text.isNotEmpty;
    return Scaffold(
      backgroundColor: const Color.fromRGBO(36, 36, 35, 1),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 15),
          child: Column(
            children: [
              _buildHeader(),
              _buildCategories(),
              if(!isSearching) ...[
                _buildSectionTitle("TRENDING NOW"),
                _buildTrendingList()
              ],
              if(isSearching) ...[
                SizedBox(height: 20)
              ],
              _buildMusicGrid(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Stack(
      children: [
        Container(
          height: 300,
          width: double.infinity,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: NetworkImage(
                "https://www.investopedia.com/thmb/QWfQNFAKm7YY7D17s30PR_WjhRU=/1500x0/filters:no_upscale():max_bytes(150000):strip_icc()/GettyImages-2196837244-cd59229199614d8da69e839d12e30909.jpg",
              ),
              fit: BoxFit.fill,
            ),
          ),
        ),
        Container(
          height: 300,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, const Color.fromRGBO(36, 36, 35, 1)],
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: _buildSearchBar(_searchController),
          ),
        ),
        Padding(
          padding: EdgeInsets.all(100),
          child: Text("ควย", style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  Widget _buildSearchBar(TextEditingController controller) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      onChanged: (value) {
        setState(() {});
      },
      decoration: InputDecoration(
        hintText: 'Search your music interested',
        hintStyle: TextStyle(color: Colors.white30),
        filled: true,
        fillColor: Colors.white10,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        suffixIcon: controller.text.isNotEmpty ? IconButton(
            icon: const Icon(Icons.clear, color: Colors.white),
            onPressed: () {
              controller.clear();
              setState(() {});
            },
          )
        : null
      ),
    );
  }

  Widget _buildCategories() {
    List<String> cats = [
      'All',
      'Pop',
      'Rock',
      'Hip Hop',
      'R&B',
      'Jazz',
      'K-Pop',
      'Indie',
      'Classical',
      'Metal',
      'EDM',
    ];
    return Wrap(
      spacing: 8.0,
      runSpacing: 1.0,
      children: cats.map((String genre) {
        final isSelected = _selectedGenre == genre;
        return ChoiceChip(
          label: Text(genre),
          labelStyle: TextStyle(
            color: isSelected ? Colors.black : Colors.white,
            fontWeight: FontWeight.bold,
          ),
          selected: isSelected,
          selectedColor: const Color(0xFF1DB954), // สีเขียวตามโค้ดคุณ
          backgroundColor: Colors.grey[800],
          checkmarkColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Colors.transparent),
          ),
          onSelected: (bool selected) {
            setState(() {
              _selectedGenre = genre;
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildSectionTitle(
    String title, {
    TextAlign? position = TextAlign.center,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            textAlign: position,
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(width: 10),
          Icon(
            Icons.local_fire_department,
            color: const Color.fromARGB(255, 216, 254, 4),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendingList() {
    final List<Map<String, String>> trendingSongs = [
      {
        'title': 'ดอกกระจิยวบาน',
        'artist': 'ศิลปิน A',
        'image': 'https://i.ytimg.com/vi/Dlz_XHeUUis/maxresdefault.jpg',
      },
      {
        'title': 'THE LOSER',
        'artist': 'URBOYTJ',
        'image':
            'https://i.scdn.co/image/ab67616d0000b2737aede4855f6d0d738012e2e5',
      },
      {
        'title': 'กลัวว่าฉันจะ...',
        'artist': 'ศิลปิน C',
        'image':
            'https://image-cdn.hypb.st/https%3A%2F%2Fhypebeast.com%2Fwp-content%2Fblogs.dir%2F6%2Ffiles%2F2023%2F01%2Ffrank2.jpg?q=75&w=800&cbr=1&fit=max',
      },
    ];
    return SizedBox(
      height: 220,

      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: trendingSongs.length,
        itemBuilder: (context, index) {
          final song = trendingSongs[index];
          return Container(
            width: 150,
            margin: const EdgeInsets.only(right: 15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.network(
                    song['image']!,
                    height: 150,
                    width: 150,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  song['title']!,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 5),
                Text(
                  song['artist']!,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMusicGrid() {
    final searchText = _searchController.text.toLowerCase();

    final filteredMusic = allMusic.where((music) {
      bool matchesGenre =
          (_selectedGenre == 'All' || music.genre == _selectedGenre);

      bool matchesSearch =
          searchText.isEmpty ||
          music.title.toLowerCase().contains(searchText) ||
          music.artist.toLowerCase().contains(searchText);

      return matchesGenre && matchesSearch;
    }).toList();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 20, left: 22),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '$_selectedGenre | ${filteredMusic.length} TRACKS',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 17,
                color: Colors.white,
              ),
            ),
          ),
        ),
        if (filteredMusic.isEmpty)
          _buildEmptyState()
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 15,
              mainAxisSpacing: 20,
              childAspectRatio: 0.75,
            ),
            itemCount: filteredMusic.length,
            itemBuilder: (context, index) =>
                _buildSongCard(filteredMusic[index]),
          ),
      ],
    );
  }

  Widget _buildSongCard(Music music, {double? width}) {
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Image.network(
                music.image,
                fit: BoxFit.cover,
                width: double.infinity,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            music.title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            music.artist,
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 50),
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.music_off_outlined, size: 80, color: Colors.white10),
          const SizedBox(height: 16),
          Text(
            "No tracks found in $_selectedGenre",
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Try selecting another category",
            style: TextStyle(color: Colors.white24, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
