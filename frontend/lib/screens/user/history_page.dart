import 'package:flutter/material.dart';
import '../../services/user_service.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  // State
  List<Map<String, dynamic>> _reviews = [];
  Map<String, dynamic>? _profile;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        ApiService.getProfile(),
        ApiService.getMyReviews(),
      ]);

      setState(() {
        _profile = results[0] as Map<String, dynamic>;
        _reviews = (results[1] as List).cast<Map<String, dynamic>>();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: _buildAppBar(context),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'เกิดข้อผิดพลาด\n$_errorMessage',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _errorMessage = null;
                });
                _loadData();
              },
              child: const Text('ลองใหม่'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        const SizedBox(height: 10),
        _buildProfileHeader(),

        // Section Title
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "HISTORY (${_reviews.length})",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              Container(height: 1, color: Colors.grey[700]),
            ],
          ),
        ),

        // List View
        Expanded(
          child: _reviews.isEmpty
              ? const Center(
                  child: Text(
                    'ยังไม่มีประวัติการรีวิว',
                    style: TextStyle(color: Colors.white54),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: _reviews.length,
                  itemBuilder: (context, index) {
                    return _buildReviewCard(_reviews[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    // ข้อมูลจาก Review model
    final beatScore = (review['beat_score'] ?? 0.0).toStringAsFixed(1);
    final lyricScore = (review['lyric_score'] ?? 0.0).toStringAsFixed(1);
    final moodScore = (review['mood_score'] ?? 0.0).toStringAsFixed(1);
    final comment = review['comment'] ?? '';
    final songId = review['song_id'];

    return FutureBuilder<Map<String, dynamic>>(
      // ดึงข้อมูลเพลงแบบ lazy โดยใช้ song_id
      future: ApiService.getSongDetail('$songId'),
      builder: (context, snapshot) {
        final coverUrl = snapshot.data?['song_cover_url'];
        final songName = snapshot.data?['song_name'] ?? 'กำลังโหลด...';
        final artistName = snapshot.data?['artist_name'] ?? '';

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
                child: coverUrl != null && coverUrl.isNotEmpty
                    ? Image.network(
                        coverUrl,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholderCover(),
                      )
                    : _placeholderCover(),
              ),
              const SizedBox(width: 16),
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      songName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      artistName,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    // Scores
                    Text(
                      "BEAT $beatScore  LYRIC $lyricScore  MOOD $moodScore",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (comment.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        comment,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 11,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _placeholderCover() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.music_note, color: Colors.white54, size: 32),
    );
  }

  Widget _buildProfileHeader() {
    final username = _profile?['username'] ?? '';
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
        Text(
          username,
          style: const TextStyle(
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
