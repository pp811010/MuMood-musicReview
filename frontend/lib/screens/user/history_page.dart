import 'package:flutter/material.dart';
import '../../core/api_client.dart';
import '../../services/user_service.dart';
import '../../services/history_service.dart';
import '../../services/song_service.dart';
import '../../models/song_detail.dart';
import '../user/song_detail.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<Map<String, dynamic>> _reviews = [];
  Map<String, dynamic>? _profile;
  final Map<String, SongDetail> _songCache = {};
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
    dataRefreshNotifier.addListener(_onDataChanged);
  }

  @override
  void dispose() {
    dataRefreshNotifier.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
    if (mounted) _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        ApiService.getProfile(),
        fetchMyReviews(),
      ]);

      if (mounted) {
        final profile = results[0] as Map<String, dynamic>;
        final reviews = (results[1] as List).cast<Map<String, dynamic>>();

        final uniqueSongIds = reviews
            .map((r) => r['song_id'].toString())
            .toSet();

        await Future.wait(
          uniqueSongIds.map((id) async {
            if (!_songCache.containsKey(id)) {
              try {
                final songData = await fetchDetailSong(id);
                if (songData != null) _songCache[id] = songData;
              } catch (_) {}
            }
          }),
        );

        if (mounted) {
          setState(() {
            _profile = profile;
            _reviews = reviews;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
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
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadData,
            color: Colors.white,
            backgroundColor: Colors.grey[900],
            child: _reviews.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.5,
                        child: const Center(
                          child: Text(
                            'ยังไม่มีประวัติการรีวิว',
                            style: TextStyle(color: Colors.white54),
                          ),
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: _reviews.length,
                    itemBuilder: (context, index) {
                      return _buildReviewCard(_reviews[index]);
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    final beatScore = (review['beat_score'] ?? 0.0).toStringAsFixed(1);
    final lyricScore = (review['lyric_score'] ?? 0.0).toStringAsFixed(1);
    final moodScore = (review['mood_score'] ?? 0.0).toStringAsFixed(1);
    final songId = review['song_id']?.toString() ?? '';

    final songData = _songCache[songId];
    final coverUrl = songData?.image;
    final songName = songData?.songName ?? 'ไม่ทราบชื่อเพลง';
    final artistName = songData?.artistName ?? '';

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => MusicDetail(id: songId)),
        );
        _loadData();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF2C2C2C),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _scoreItem("Beat", beatScore),
                      _scoreItem("Lyric", lyricScore),
                      _scoreItem("Mood", moodScore),
                    ],
                  ),
                  // ── comment ถูกแยกออกไปแล้ว ไม่แสดงใน history card ──
                  // ถ้าต้องการดู comment ให้กดเข้าไปใน song detail
                  const SizedBox(height: 4),
                  Text(
                    "Tap to view comments",
                    style: TextStyle(color: Colors.white24, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholderCover() {
    return Container(
      width: 80,
      height: 80,
      color: Colors.grey[800],
      child: const Icon(Icons.music_note, color: Colors.white54, size: 30),
    );
  }

  Widget _scoreItem(String label, String score) {
    return Column(
      children: [
        Text(
          score,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
      ],
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
      automaticallyImplyLeading: false,
    );
  }
}
