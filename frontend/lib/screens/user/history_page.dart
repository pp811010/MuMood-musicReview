import 'package:flutter/material.dart';
import '../../core/api_client.dart';
import '../../services/user_service.dart';
import '../../services/history_service.dart';
import '../../services/song_service.dart';
import '../../models/song_detail.dart';
import 'song_detail_page.dart';

class _HistoryEntry {
  final String songId;
  final bool hasReview;
  final Map<String, dynamic>? reviewData;
  final int commentCount;

  const _HistoryEntry({
    required this.songId,
    required this.hasReview,
    this.reviewData,
    required this.commentCount,
  });
}

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<_HistoryEntry> _entries = [];
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
        fetchMyCommentHistory(),
      ]);

      final profile = results[0] as Map<String, dynamic>;
      final reviews = (results[1] as List).cast<Map<String, dynamic>>();
      final commentGroups = (results[2] as List).cast<Map<String, dynamic>>();

      final reviewBySongId = <String, Map<String, dynamic>>{};
      for (final r in reviews) {
        reviewBySongId[r['song_id'].toString()] = r;
      }

      final commentCountBySongId = <String, int>{};
      for (final g in commentGroups) {
        commentCountBySongId[g['song_id'].toString()] = g['count'] as int;
      }

      final allSongIds = <String>{
        ...reviewBySongId.keys,
        ...commentCountBySongId.keys,
      };

      await Future.wait(
        allSongIds.map((id) async {
          if (!_songCache.containsKey(id)) {
            try {
              final songData = await fetchDetailSong(id);
              if (songData != null) _songCache[id] = songData;
            } catch (_) {}
          }
        }),
      );

      final entries =
          allSongIds.map((id) {
            return _HistoryEntry(
              songId: id,
              hasReview: reviewBySongId.containsKey(id),
              reviewData: reviewBySongId[id],
              commentCount: commentCountBySongId[id] ?? 0,
            );
          }).toList()..sort((a, b) {
            final aScore = (a.hasReview ? 2 : 0) + (a.commentCount > 0 ? 1 : 0);
            final bScore = (b.hasReview ? 2 : 0) + (b.commentCount > 0 ? 1 : 0);
            return bScore.compareTo(aScore);
          });

      if (mounted) {
        setState(() {
          _profile = profile;
          _entries = entries;
          _isLoading = false;
          _errorMessage = null;
        });
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
              'Error\n$_errorMessage',
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
              child: const Text('Try Again'),
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
                "HISTORY (${_entries.length})",
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
            child: _entries.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.5,
                        child: const Center(
                          child: Text(
                            'No Review or Comment',
                            style: TextStyle(color: Colors.white54),
                          ),
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: _entries.length,
                    itemBuilder: (context, index) {
                      return _buildHistoryCard(_entries[index]);
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryCard(_HistoryEntry entry) {
    final songData = _songCache[entry.songId];
    final coverUrl = (songData?.image?.startsWith('/') == true)
        ? 'http://10.0.2.2:8000${songData!.image}'
        : songData?.image;
    final songName = songData?.songName ?? 'Unknow Song Name';
    final artistName = songData?.artistName ?? '';

    final beatScore = entry.reviewData != null
        ? (entry.reviewData!['beat_score'] ?? 0.0).toStringAsFixed(1)
        : null;
    final lyricScore = entry.reviewData != null
        ? (entry.reviewData!['lyric_score'] ?? 0.0).toStringAsFixed(1)
        : null;
    final moodScore = entry.reviewData != null
        ? (entry.reviewData!['mood_score'] ?? 0.0).toStringAsFixed(1)
        : null;

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SongDetailPage(id: entry.songId),
          ),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _typeBadge(
                  label: 'Review',
                  icon: Icons.star_rounded,
                  color: const Color(0xFFFFD700),
                  active: entry.hasReview,
                ),
                const SizedBox(width: 8),
                _typeBadge(
                  label: entry.commentCount > 0
                      ? 'Comment (${entry.commentCount})'
                      : 'Comment',
                  icon: Icons.chat_bubble_rounded,
                  color: const Color(0xFF64B5F6),
                  active: entry.commentCount > 0,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
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
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 12),

                      if (entry.hasReview && beatScore != null)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _scoreItem("Beat", beatScore),
                            _scoreItem("Lyric", lyricScore!),
                            _scoreItem("Mood", moodScore!),
                          ],
                        )
                      else
                        Text(
                          'This song hasn\'t been reviewed yet',
                          style: TextStyle(color: Colors.white30, fontSize: 12),
                        ),
                    ],
                  ),
                ),
              ],
            ),

            if (entry.commentCount > 0) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.chat_bubble_outline,
                      color: Colors.white38,
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'You have ${entry.commentCount} comment on this song • Tap to view',
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              const SizedBox(height: 8),
              const Text(
                'No comment yet • Tap to comment',
                style: TextStyle(color: Colors.white54, fontSize: 11),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _typeBadge({
    required String label,
    required IconData icon,
    required Color color,
    required bool active,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: active
            ? color.withOpacity(0.15)
            : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: active ? color.withOpacity(0.6) : Colors.white12,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: active ? color : Colors.white24),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: active ? color : Colors.white24,
              fontWeight: active ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
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
