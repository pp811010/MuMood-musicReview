import 'package:flutter/material.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final _searchController = TextEditingController();
  String _selectedGenre = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(36, 36, 35, 1),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            _buildCategories(),
            _buildSectionTitle("TRENDING NOW"),
          ],
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
      ],
    );
  }

  Widget _buildSearchBar(TextEditingController controller) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
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

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}