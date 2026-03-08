import 'package:flutter/material.dart';
import '../../core/api_client.dart';
import '../../models/song_detail.dart';
import '../../services/history_service.dart';
import '../../services/song_service.dart';
import '../../services/user_service.dart';
import '../../widgets/page_state_handler.dart';
import '../../widgets/profile_header.dart';
import '../../widgets/section_header.dart';
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

      final profile = results[0] as Map<String, dynamic>;
      final reviews = (results[1] as List).cast<Map<String, dynamic>>();

      // Fetch song details for uncached songs
      final uniqueSongIds = reviews.map((r) => r['song_id'].toString()).toSet();
      await Future.wait(
        uniqueSongIds
            .where((id) => !_songCache.containsKey(id))
            .map((id) async {
          try {
            final songData = await fetchDetailSong(id);
            if (songData != null) _songCache[id] = songData;
          } catch (_) {}
        }),
      );

      if (!mounted) return;
      setState(() {
        _profile = profile;
        _reviews = reviews;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _onRetry() {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: PageStateHandler(
        isLoading: _isLoading,
        errorMessage: _errorMessage,
        onRetry: _onRetry,
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        const SizedBox(height: 10),
        ProfileHeader(username: _profile?['username'] ?? ''),
        SectionHeader(title: 'HISTORY (${_reviews.length})'),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadData,
            color: Colors.white,
            backgroundColor: Colors.grey[900],
            child: _reviews.isEmpty
                ? _buildEmptyState()
                : _buildReviewList(),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return ListView(
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
    );
  }

  Widget _buildReviewList() {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: _reviews.length,
      itemBuilder: (context, index) => _buildReviewCard(_reviews[index]),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    final songId = review['song_id']?.toString() ?? '';
    final songData = _songCache[songId];

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => MusicDetail(id: songId)),
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
            _buildCoverImage(songData?.image),
            const SizedBox(width: 16),
            Expanded(
              child: _buildReviewDetails(
                songName: songData?.songName ?? 'ไม่ทราบชื่อเพลง',
                artistName: songData?.artistName ?? '',
                review: review,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoverImage(String? coverUrl) {
    if (coverUrl != null && coverUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          coverUrl,
          width: 80,
          height: 80,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _coverPlaceholder(),
        ),
      );
    }
    return _coverPlaceholder();
  }

  Widget _coverPlaceholder() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.music_note, color: Colors.white54, size: 30),
    );
  }

  Widget _buildReviewDetails({
    required String songName,
    required String artistName,
    required Map<String, dynamic> review,
  }) {
    final comment = review['comment'] ?? '';

    return Column(
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
        Text(artistName, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildScoreItem('Beat', review['beat_score']),
            _buildScoreItem('Lyric', review['lyric_score']),
            _buildScoreItem('Mood', review['mood_score']),
          ],
        ),
        if (comment.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '"$comment"',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildScoreItem(String label, dynamic rawScore) {
    final score = (rawScore ?? 0.0).toStringAsFixed(1);
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
}