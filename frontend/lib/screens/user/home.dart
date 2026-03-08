import 'dart:convert';
import 'package:frontend/core/api_client.dart';
import 'package:frontend/widgets/song.card.dart';
import 'package:frontend/widgets/song_card_shimmer.dart';
import 'package:frontend/widgets/trending_list.dart';
import 'package:flutter/material.dart';
import 'package:frontend/models/music.dart';
import 'dart:async';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  String _selectedGenre = 'All';
  List<Map<String, String>> _trendingSongs = [];
  bool _isLoadingTrending = false;

  List<Music> _genreSongs = [];
  bool _isLoadingGenre = false;

  List<Music> _searchResults = [];
  bool _isLoadingSearch = false;

  @override
  void initState() {
    super.initState();
    _fetchTopchart();
    _fetchSongsByGenre(_selectedGenre);
  }

  Future<void> _fetchTopchart() async {
    setState(() => _isLoadingTrending = true);
    try {
      final response = await ApiClient.get('/spotify/top-charts');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List<dynamic> thCharts = data['charts']['TH'] ?? [];
        setState(() {
          _trendingSongs = thCharts
              .map<Map<String, String>>(
                (item) => {
                  'title': item['song_name']?.toString() ?? '',
                  'artist': item['artist_name']?.toString() ?? '',
                  'image': item['song_cover_url']?.toString() ?? '',
                },
              )
              .toList();
        });
      }
    } catch (e) {
      debugPrint('Error fetching top chart: $e');
    } finally {
      setState(() => _isLoadingTrending = false);
    }
  }

  Future<void> _searchSongs(String query) async {
    if (query.isEmpty) return;
    setState(() => _isLoadingSearch = true);
    try {
      final response = await ApiClient.get('/songs/search?q=$query');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List<dynamic> results = data['results'] ?? [];
        setState(() {
          _searchResults = results
              .map<Music>(
                (item) => Music(
                  id: item['id'],
                  title: item['name'] ?? '',
                  artist: item['artist'] ?? '',
                  genre: '',
                  image: item['image'] ?? '',
                ),
              )
              .toList();
        });
      }
    } catch (e) {
      debugPrint('Error searching: $e');
    } finally {
      setState(() => _isLoadingSearch = false);
    }
  }

  Future<void> _fetchSongsByGenre(String genre) async {
    setState(() => _isLoadingGenre = true);
    try {
      final response = await ApiClient.get(
        '/spotify/songs-by-genre?genre=${genre.toLowerCase()}&limit=10',
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List<dynamic> songs = data['songs'] ?? [];
        setState(() {
          _genreSongs = songs
              .map<Music>(
                (item) => Music(
                  id: item['id'].toString(),
                  title: item['song_name'] ?? '',
                  artist: item['artist_name'] ?? '',
                  genre: genre,
                  image: item['song_cover_url'] ?? '',
                ),
              )
              .toList();
        });
      }
    } catch (e) {
      debugPrint('Error fetching songs by genre: $e');
    } finally {
      setState(() => _isLoadingGenre = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Widget build(BuildContext context) {
    bool isSearching = _searchController.text.isNotEmpty;
    return Scaffold(
      backgroundColor: const Color(0xFF0e0e0e),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 15),
          child: Column(
            children: [
              _buildHeader(),
              if (!isSearching) _buildCategories(),
              if (!isSearching) ...[
                _buildSectionTitle("TRENDING 2025 IN SPOFITY (TH)"),
                TrendingList(
                  trendingSongs: _trendingSongs,
                  isLoading: _isLoadingTrending,
                ),
              ],
              if (!isSearching)
                Padding(
                  padding: const EdgeInsets.only(
                    bottom: 20,
                    left: 22,
                    right: 22,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$_selectedGenre Tracks',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.bubble_chart_outlined,
                          color: Colors.white,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              if (isSearching) ...[
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.only(
                    bottom: 20,
                    left: 10,
                    right: 10,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Results for "${_searchController.text}"',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                          color: Colors.white,
                        ),
                      ),
                      const Icon(Icons.search, color: Colors.white, size: 18),
                    ],
                  ),
                ),
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
                "https://ca-times.brightspotcdn.com/dims4/default/f854f6b/2147483647/strip/true/crop/5568x3712+0+0/resize/1200x800!/quality/75/?url=https%3A%2F%2Fcalifornia-times-brightspot.s3.amazonaws.com%2Faa%2F18%2Fe54c32e242b684c943ea0cf6c222%2Fap21310170175809.jpg",
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
      ],
    );
  }

  Widget _buildSearchBar(TextEditingController controller) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      onChanged: (value) {
        setState(() {});
        if (_debounce?.isActive ?? false) _debounce!.cancel();
        _debounce = Timer(const Duration(milliseconds: 1000), () {
          if (value.isNotEmpty) {
            _searchSongs(value);
          } else {
            setState(() => _searchResults = []);
          }
        });
      },
      decoration: InputDecoration(
        hintText: 'Search your music interested',
        hintStyle: TextStyle(color: Colors.white54),
        filled: true,
        fillColor: Colors.white10,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        suffixIcon: controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, color: Colors.white),
                onPressed: () {
                  controller.clear();
                  setState(() {});
                },
              )
            : null,
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
            setState(() => _selectedGenre = genre);
            _fetchSongsByGenre(genre);
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
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
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
          // Icon(
          //   Icons.local_fire_department,
          //   color: const Color.fromARGB(255, 30, 132, 220),
          // ),
        ],
      ),
    );
  }

  Widget _buildMusicGrid() {
    final isSearching = _searchController.text.isNotEmpty;

    if (_isLoadingSearch || _isLoadingGenre) {
      return const SongCardShimmer();
    }

    final displayMusic = isSearching ? _searchResults : _genreSongs;

    return Column(
      children: [
        if (displayMusic.isEmpty)
          _buildEmptyState()
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 15,
              mainAxisSpacing: 20,
              childAspectRatio: 0.75,
            ),
            itemCount: displayMusic.length,
            itemBuilder: (context, index) =>
                SongCard(music: displayMusic[index]),
          ),
      ],
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
            "No tracks found",
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
