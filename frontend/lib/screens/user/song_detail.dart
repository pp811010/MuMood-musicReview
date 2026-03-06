import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frontend/core/api_client.dart';
import 'package:frontend/models/comment.dart';
import 'package:frontend/models/emotion.dart';
import 'package:frontend/models/mood_color.dart';
import 'package:frontend/models/song_detail.dart';
import 'package:frontend/widgets/comment_card.dart';
import 'package:frontend/widgets/score_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MusicDetail extends StatefulWidget {
  final String id;
  const MusicDetail({super.key, required this.id});

  @override
  State<MusicDetail> createState() => _MusicDetailState();
}

class _MusicDetailState extends State<MusicDetail> {
  bool isfavorite = false;
  Color selectedColor = Colors.purple;
  String? selectedEmotion;
  bool openReview = false;
  late Map<String, int> emotionCounts;
  double? beatValue;
  double? lyricValue;
  double? moodValue;
  bool _isSubmitting = false;
  int meId = 10;
  late final TextEditingController _commentController = TextEditingController();

  bool hasMyComment = false;
  Comment? myComment;

  bool _loadingEmotion = false;
  List<Emotion> allEmotion = [];

  bool _loadingMoodColor = false;
  List<MoodColor> allMoodColor = [];

  bool _loadingSongDetail = false;
  SongDetail? songDetail;

  String myUserName = '';
  int? selectedEmotionId;
  int? selectedMoodColorId;
  Map<String, dynamic> myReview = {};

  @override
  void initState() {
    super.initState();
    _fetchEmotion();
    _fetchMood();
    _fetchDetailSong();
    _getPerfs();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _getPerfs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      myUserName = prefs.getString('username') ?? '';
    });
  }

  Color hexToColor(String hex) {
    hex = hex.replaceAll('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  Future<void> _fetchEmotion() async {
    setState(() => _loadingEmotion = true);
    try {
      // ✅ เปลี่ยนมาใช้ ApiClient
      final response = await ApiClient.get('/emotion/');

      if (response.statusCode == 200) {
        final List<dynamic> result = jsonDecode(response.body) ?? [];
        if (result.isNotEmpty) {
          setState(() {
            allEmotion = result
                .map<Emotion>(
                  (item) => Emotion(id: item['id'], name: item['name']),
                )
                .toList();
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching emotion: $e');
    } finally {
      setState(() => _loadingEmotion = false);
    }
  }

  Future<void> _fetchMood() async {
    setState(() => _loadingMoodColor = true);
    try {
      // ✅ เปลี่ยนมาใช้ ApiClient
      final response = await ApiClient.get('/mood-color/');

      if (response.statusCode == 200) {
        final List<dynamic> result = jsonDecode(response.body);
        if (result.isNotEmpty) {
          setState(() {
            allMoodColor = result
                .map<MoodColor>(
                  (item) => MoodColor(
                    id: item['id'],
                    colorHex: item['color_hex'],
                    colorName: item['color_name'],
                  ),
                )
                .toList();
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching mood: $e');
    } finally {
      setState(() => _loadingMoodColor = false);
    }
  }

 Future<void> _fetchDetailSong({bool isSilent = false}) async {
  if (!isSilent) setState(() => _loadingSongDetail = true);
  try {
    // ✅ ดึง song detail ก่อน ไม่ต้องรอ myReview
    final response = await ApiClient.get('/songs/detail/${widget.id}');

    if (response.statusCode == 200) {
      final Map<String, dynamic> result = jsonDecode(response.body);
      final avg = result['avg_scores'] as Map<String, dynamic>? ?? {};
      final emotions = result['emotion_counts'] as Map<String, dynamic>? ?? {};
      final colors = result['color_counts'] as Map<String, dynamic>? ?? {};
      final comments = result['comment'] as List? ?? [];

      setState(() {
        // ✅ avg scores แสดงใน ScoreCard เท่านั้น ไม่ overwrite slider
        isfavorite = result['favorite'] ?? false;
        emotionCounts = emotions.map((key, value) => MapEntry(key, value as int));
        songDetail = SongDetail(
          id: result['id'],
          image: result['song_cover_url'],
          songName: result['song_name'],
          dominantColor: result['dominant_color'],
          artistName: result['artist_name'],
          favorite: result['favorite'] ?? false,
          avgScores: avg.map((k, v) => MapEntry(k, (v as num).toDouble())),
          emotionCounts: emotions.map((k, v) => MapEntry(k, v as int)),
          colorCounts: colors.map((k, v) => MapEntry(k, v as int)),
          comment: comments,
          source: result['source'] ?? '',
        );
      });
    }

    // ✅ ดึง myReview แยก หลังจาก song detail เสร็จ
    await _fetchMyReview();

  } catch (e) {
    debugPrint('Error fetching song detail: $e');
  } finally {
    if (!isSilent) setState(() => _loadingSongDetail = false);
  }
}

 Future<void> _fetchMyReview() async {
  try {
    final response = await ApiClient.get(
      '/review/me?song_identifier=${widget.id}',
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        myReview = data;
        // ✅ slider ใช้ค่าจาก myReview ของ user เท่านั้น
        beatValue = (data['beat_score'] as num).toDouble();
        lyricValue = (data['lyric_score'] as num).toDouble();
        moodValue = (data['mood_score'] as num).toDouble();
        selectedEmotionId = data['emotion_id'];
        if (selectedEmotionId != null) {
          final foundEmotion = allEmotion.firstWhere(
            (e) => e.id == selectedEmotionId,
            orElse: () => allEmotion.first,
          );
          selectedEmotion = foundEmotion.name;
        }
        selectedMoodColorId = data['mood_color_id'];
        if (selectedMoodColorId != null) {
          final foundMood = allMoodColor.firstWhere(
            (m) => m.id == selectedMoodColorId,
            orElse: () => allMoodColor.first,
          );
          selectedColor = hexToColor(foundMood.colorHex);
        }
        _commentController.text = data['comment'] ?? '';
      });
    } else {
      // ✅ ยังไม่เคย review → reset slider เป็น 0
      setState(() {
        myReview = {};
        beatValue = 0;
        lyricValue = 0;
        moodValue = 0;
        selectedEmotionId = null;
        selectedMoodColorId = null;
        selectedEmotion = null;
      });
    }
  } catch (e) {
    debugPrint("Error fetching my review: $e");
    setState(() {
      myReview = {};
      beatValue = 0;
      lyricValue = 0;
      moodValue = 0;
    });
  }
}

  Future<void> _updateSharedRating() async {
    bool isDataChanged() {
      return beatValue != myReview['beat_score'] ||
          lyricValue != myReview['lyric_score'] ||
          moodValue != myReview['mood_score'] ||
          selectedEmotionId != myReview['emotion_id'] ||
          selectedMoodColorId != myReview['mood_color_id'];
    }

    if (!isDataChanged()) return;

    // ✅ เปลี่ยนมาใช้ ApiClient
    final response = await ApiClient.put('/review/${myReview['id']}', {
      "beat_score": beatValue,
      "lyric_score": lyricValue,
      "mood_score": moodValue,
      "emotion_id": selectedEmotionId,
      "mood_color_id": selectedMoodColorId,
    });

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Update successful!"),
          backgroundColor: Colors.green,
        ),
      );
      await _fetchDetailSong(isSilent: true);
    } else {
      debugPrint("Update failed: ${response.body}");
    }
  }

  Future<void> _submitSharedRating() async {
    if (_isSubmitting) return; // ✅ กัน double tap
    if (!_isReviewComplete()) {
      _showIncompleteWarning();
      return;
    }

    setState(() => _isSubmitting = true); // ✅ ล็อก

    try {
      final response = await ApiClient.post('/review/', {
        "song_id_reference": songDetail!.id.toString(),
        "emotion_id": selectedEmotionId,
        "mood_color_id": selectedMoodColorId,
        "beat_score": beatValue,
        "lyric_score": lyricValue,
        "mood_score": moodValue,
        "source": songDetail!.source,
      });

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Rating submitted!"),
            backgroundColor: Colors.green,
          ),
        );
        await _fetchDetailSong(isSilent: true);
      } else {
        final error = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error['detail'] ?? 'Something went wrong'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isSubmitting = false); // ✅ ปลดล็อกเสมอ
    }
  }

  Future<void> _submitComment() async {
    if (_commentController.text.trim().isEmpty) return;

    final response = await ApiClient.put('/review/${myReview['id']}', {
      "comment": _commentController.text,
    });

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Comment saved!")));
      await _fetchDetailSong(isSilent: true);
      setState(() => openReview = false);
    } else {
      debugPrint("Error: ${response.body}");
    }
  }

  Future<void> _updateComment() async {
    // ✅ เปลี่ยนมาใช้ ApiClient
    final response = await ApiClient.put('/review/${myReview['id']}', {
      "comment": _commentController.text,
    });

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Comment updated!"),
          backgroundColor: Colors.green,
        ),
      );
      await _fetchDetailSong(isSilent: true);
      setState(() {
        openReview = false;
        _commentController.clear();
      });
    } else {
      debugPrint("Update failed: ${response.body}");
    }
  }

  Future<void> _toggleFavorite() async {
    // ✅ เปลี่ยนมาใช้ ApiClient
    final response = await ApiClient.post('/favorites/toggle', {
      "song_id_reference": widget.id.toString(),
      "source": "spotify",
    });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() => isfavorite = data['is_favorited']);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(data['message'])));
    }
  }

  bool _isReviewComplete() {
    return selectedEmotionId != null &&
        selectedMoodColorId != null &&
        beatValue! > 0 &&
        lyricValue! > 0 &&
        moodValue! > 0;
  }

  Future<void> createComment() async {
    if (_commentController.text.trim().isEmpty) return;

    // ✅ เช็คก่อน comment ด้วย
    if (myReview.isEmpty && !_isReviewComplete()) {
      _showIncompleteWarning();
      return;
    }

    try {
      if (myReview['comment'] == null) {
        await _submitComment();
      } else {
        await _updateComment();
      }

      setState(() {
        openReview = false;
        _commentController.clear();
        hasMyComment = true;
      });
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  // เพิ่ม helper แสดง error ว่าขาดอะไร
  void _showIncompleteWarning() {
    List<String> missing = [];
    if (selectedEmotionId == null) missing.add('Emotion');
    if (selectedMoodColorId == null) missing.add('Color Mood');
    if (beatValue == 0) missing.add('Beat Score');
    if (lyricValue == 0) missing.add('Lyric Score');
    if (moodValue == 0) missing.add('Mood Score');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.black),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Please complete: ${missing.join(', ')}',
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFFFD60A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (songDetail == null) {
      return Scaffold(
        backgroundColor: Color(0xFF0e0e0e),
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }
    return Scaffold(
      backgroundColor: const Color(0xFF0e0e0e),
      body: SafeArea(
        child: Stack(
          children: [
            Stack(
              children: [
                if (songDetail!.dominantColor != null) ...{
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          hexToColor(songDetail!.dominantColor!),
                          hexToColor(
                            songDetail!.dominantColor!,
                          ).withOpacity(0.7),
                          hexToColor(
                            songDetail!.dominantColor!,
                          ).withOpacity(0.2),
                          Color(0xFF0E0E0E),
                        ],
                        stops: const [0.2, 0.3, 0.7, 1.0],
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.0),
                          Colors.black.withOpacity(0.25),
                          Colors.black.withOpacity(0.55),
                        ],
                      ),
                    ),
                  ),
                },
                CustomScrollView(
                  slivers: [
                    SliverAppBar(
                      floating: true,
                      snap: true,
                      backgroundColor: Colors.transparent,
                      leading: IconButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        icon: Icon(Icons.arrow_back_ios),
                        color: Colors.white,
                      ),
                      title: Text(
                        songDetail!.songName,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      centerTitle: true,
                      actions: [
                        IconButton(
                          onPressed: () {
                            _toggleFavorite();
                          },
                          icon: isfavorite
                              ? Icon(Icons.favorite)
                              : Icon(Icons.favorite_border),
                          color: isfavorite ? Color(0xFF1DB954) : Colors.white,
                        ),
                      ],
                    ),

                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            _buildMusicCover(),
                            const SizedBox(height: 30),
                            _buildEmotionsSection(),
                            const SizedBox(height: 30),
                            _buildRatingMusicDetail(),
                            const SizedBox(height: 25),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                "Color Mood",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                            const SizedBox(height: 15),
                            SizedBox(
                              height: 45,
                              child: _loadingMoodColor
                                  ? CircularProgressIndicator(
                                      color: Colors.white,
                                    )
                                  : ListView(
                                      scrollDirection: Axis.horizontal,
                                      children: allMoodColor.map((mood) {
                                        final color = hexToColor(mood.colorHex);
                                        final count =
                                            songDetail?.colorCounts[mood
                                                .colorHex] ??
                                            0;
                                        return _buildColorOption(
                                          mood.id,
                                          color,
                                          count: count,
                                        );
                                      }).toList(),
                                    ),
                            ),
                            const SizedBox(height: 20),
                            Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _isSubmitting
                                      ? Colors
                                            .grey // ✅ สีเทาตอน loading
                                      : const Color.fromARGB(
                                          255,
                                          254,
                                          255,
                                          255,
                                        ),
                                ),
                                onPressed: _isSubmitting
                                    ? null
                                    : () {
                                        // ✅ disable ตอน submitting
                                        if (myReview.isEmpty) {
                                          _submitSharedRating();
                                        } else {
                                          _updateSharedRating();
                                        }
                                      },
                                child: _isSubmitting
                                    ? const SizedBox(
                                        // ✅ แสดง loading spinner
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          color: Colors.black,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(
                                        "Shared Rating",
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.black,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            _buildHeaderComment(),
                            const SizedBox(height: 15),
                            _buildAllComment(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderComment() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,

          children: [
            Text(
              "Comment",
              style: TextStyle(
                color: const Color.fromARGB(255, 200, 200, 200),
                fontSize: 18,
              ),
            ),
            SizedBox(
              width: 100,
              height: 30,
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    openReview = !openReview;
                    if (myReview['comment'] != null && openReview) {
                      _commentController.text = myReview['comment'];
                    } else {
                      _commentController.clear();
                    }
                  });
                },
                style: ButtonStyle(
                  maximumSize: WidgetStatePropertyAll(Size(80, 40)),
                ),
                child: Text(
                  myReview['comment'] != null ? "Edit" : "Review",
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ],
        ),
        if (openReview) ...{_buildNewComment()},
      ],
    );
  }

  Container _buildNewComment() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 15, vertical: 25),
      height: 300,
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 19,
                backgroundImage: NetworkImage(
                  'https://cms.dmpcdn.com/dara/2020/12/14/e449fab0-3dc4-11eb-9b6d-3fdf37c2e48e_original.jpg',
                ),
              ),
              SizedBox(width: 13),
              Text(
                myUserName,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Spacer(),
              if (hasMyComment)
                IconButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: Color(0xFF2A2A2A),
                        title: Text(
                          "Delete Comment",
                          style: TextStyle(color: Colors.white),
                        ),
                        content: Text(
                          "Are you sure you want to delete this comment?",
                          style: TextStyle(color: Colors.white70),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              "Cancel",
                              style: TextStyle(color: Colors.white70),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _updateComment();
                                myComment = null;
                                hasMyComment = false;
                                openReview = false;
                                _commentController.clear();
                              });
                              Navigator.pop(context);
                            },
                            child: Text(
                              "Delete",
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: Icon(Icons.delete_outline),
                  color: Colors.red,
                  iconSize: 22,
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                ),
            ],
          ),
          SizedBox(height: 20),
          Expanded(
            child: TextField(
              controller: _commentController,
              autofocus: true,
              maxLines: 5,
              style: TextStyle(color: Colors.white),
              keyboardType: TextInputType.multiline,
              decoration: InputDecoration(
                hintText: "Enter you opinion",
                hintStyle: TextStyle(color: Colors.white70),
              ),
            ),
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton(
                style: ButtonStyle(
                  backgroundColor: WidgetStatePropertyAll(Colors.transparent),
                ),
                onPressed: () {
                  setState(() {
                    openReview = false;
                    _commentController.clear();
                  });
                },
                child: Text(
                  "Cancel",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              SizedBox(width: 10),
              ElevatedButton(
                onPressed: () {
                  createComment();
                },
                child: Text(
                  hasMyComment ? "Save" : "Submit",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRatingMusicDetail() {
    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            "Music Detail",
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
        ),
        SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: ScoreCard(
                score:
                    songDetail!.avgScores['beat']?.toStringAsFixed(2) ?? '0.00',
                label: 'Beat',
              ),
            ),
            Expanded(
              child: ScoreCard(
                score:
                    songDetail!.avgScores['lyric']?.toStringAsFixed(2) ??
                    '0.00',
                label: 'Lyric',
              ),
            ),
            Expanded(
              child: ScoreCard(
                score:
                    songDetail!.avgScores['mood']?.toStringAsFixed(2) ?? '0.00',
                label: 'Mood',
              ),
            ),
          ],
        ),
        SizedBox(height: 10),
        _buildEQSlider(
          'Beat',
          const Color.fromARGB(255, 104, 228, 106),
          beatValue!,
          (value) {
            setState(() => beatValue = value);
          },
        ),
        _buildEQSlider(
          'Lyric',
          const Color.fromARGB(255, 166, 1, 1),
          lyricValue!,
          (value) {
            setState(() => lyricValue = value);
          },
        ),
        _buildEQSlider(
          'Mood',
          const Color.fromARGB(174, 109, 3, 162),
          moodValue!,
          (value) {
            setState(() => moodValue = value);
          },
        ),
      ],
    );
  }

  Widget _buildAllComment() {
    debugPrint(songDetail!.comment.toString());
    if (songDetail!.comment.isEmpty) {
      return Container(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(Icons.chat_bubble_outline, color: Colors.white24, size: 48),
            SizedBox(height: 12),
            Text(
              "No comments yet",
              style: TextStyle(color: Colors.white38, fontSize: 16),
            ),
          ],
        ),
      );
    }
    List sortedComments = List.from(songDetail!.comment);
    sortedComments.sort((a, b) {
      DateTime dateA = DateTime.parse(a['created_at']);
      DateTime dateB = DateTime.parse(b['created_at']);
      return dateB.compareTo(dateA);
    });

    return ListView.separated(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      separatorBuilder: (context, index) => SizedBox(height: 15),
      itemCount: sortedComments.length,
      itemBuilder: (context, index) {
        final item = sortedComments[index] as Map<String, dynamic>;
        final comment = Comment(
          id: index,
          ownerId: item['user_id'] ?? 0,
          ownername: item['username'] ?? '',
          text: item['comment'] ?? '',
        );
        return CommentCard(comment: comment);
      },
    );
  }

  Widget _buildColorOption(int id, Color color, {int count = 0}) {
    final bool isSelected = selectedColor == color;
    return GestureDetector(
      onTap: () =>
          setState(() => (selectedColor = color, selectedMoodColorId = id)),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        margin: EdgeInsets.only(right: 10),
        width: isSelected ? 52 : 45,
        height: isSelected ? 52 : 45,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(isSelected ? 14 : 10),
          border: isSelected
              ? Border.all(color: Colors.white, width: 3)
              : Border.all(color: Colors.white.withOpacity(0.2), width: 1),
        ),
        child: count > 0
            ? Center(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildEQSlider(
    String label,
    Color color,
    double value,
    Function(double) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                // พื้นหลังสีเทา
                Container(
                  height: 21,
                  decoration: BoxDecoration(
                    color: Colors.grey[700],
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                // ส่วนที่เติมสีเขียว
                ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width:
                          (MediaQuery.of(context).size.width - 140) *
                          (value / 5), // คำนวณความกว้างตาม value
                      height: 21,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ),
                ),
                // Slider โปร่งใส
                SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 21,
                    activeTrackColor: Colors.transparent,
                    inactiveTrackColor: Colors.transparent,
                    thumbShape: RoundSliderThumbShape(
                      enabledThumbRadius: 0,
                    ), // ซ่อน thumb
                    overlayShape: RoundSliderOverlayShape(overlayRadius: 0),
                  ),
                  child: Slider(
                    value: value,
                    min: 0,
                    max: 5,
                    onChanged: onChanged,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 10),
          SizedBox(
            width: 40,
            child: Text(
              value.toStringAsFixed(2),
              style: const TextStyle(color: Colors.white, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(width: 10),
          Container(child: Column(children: [Row()])),
        ],
      ),
    );
  }

  Widget _buildEmotionsSection() {
    if (_loadingEmotion) {
      return CircularProgressIndicator(color: Colors.white);
    }

    final Map<String, IconData> emotionIcons = {
      'Happy': Icons.sentiment_very_satisfied,
      'Sad': Icons.sentiment_very_dissatisfied,
      'In Love': Icons.favorite,
      'Lonely': Icons.nightlight_round,
      'Missing': Icons.psychology,
      'Heartbroken': Icons.heart_broken,
    };

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 20,
      children: allEmotion.map((emotion) {
        return _buildEmotionIcon(
          emotion.id,
          emotionIcons[emotion.name]!,
          emotion.name,
        );
      }).toList(),
    );
  }

  Widget _buildEmotionIcon(int id, IconData icon, String emotion) {
    bool isSelected = selectedEmotion == emotion;
    int count = emotionCounts[emotion] ?? 0;

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            selectedEmotion = null;
            emotionCounts[emotion] = count - 1;
          } else {
            if (selectedEmotion != null) {
              emotionCounts[selectedEmotion!] =
                  (emotionCounts[selectedEmotion!] ?? 1) - 1;
            }
            selectedEmotion = emotion;
            selectedEmotionId = id;
            emotionCounts[emotion] = count + 1;
          }
        });
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: isSelected
              ? selectedColor.withOpacity(0.9)
              : Color(0xFF2A2A2A),
          border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
        ),
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? Color.fromRGBO(255, 174, 174, 1)
                  : Colors.white.withOpacity(0.6),
              size: 17,
            ),
            SizedBox(width: 6),
            Text(
              emotion,
              style: TextStyle(
                fontSize: 14,
                color: isSelected
                    ? Color.fromRGBO(255, 174, 174, 1)
                    : Colors.white.withOpacity(0.8),
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: 0.3,
              ),
            ),
            SizedBox(width: 6),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? Color(0xFF1A1A1A).withOpacity(0.3)
                    : Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 11,
                  color: isSelected
                      ? Color.fromRGBO(255, 174, 174, 1)
                      : Colors.white.withOpacity(0.5),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Column _buildMusicCover() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Stack(
          children: [
            Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey[900],
                boxShadow: [
                  BoxShadow(
                    color: selectedColor.withValues(alpha: 0.5),
                    blurRadius: 40,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  songDetail!.image ?? '',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[800],
                      child: const Center(
                        child: Icon(
                          Icons.music_note,
                          size: 80,
                          color: Colors.white54,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 25),
        Text(
          songDetail!.songName,
          style: TextStyle(fontSize: 18, color: Colors.white),
        ),
        Text(
          songDetail!.artistName,
          style: TextStyle(fontSize: 18, color: Colors.white24),
        ),
      ],
    );
  }

  // Widget _buildTopBar(BuildContext context) {
  //   return Row(
  //     children: [
  //       IconButton(
  //         onPressed: () {
  //           Navigator.pop(context);
  //         },
  //         icon: Icon(Icons.arrow_back_ios),
  //         color: Colors.white,
  //       ),
  //       Spacer(),
  //       Text(
  //         songDetail!.songName,
  //         style: TextStyle(
  //           color: Colors.white,
  //           fontSize: 18,
  //           fontWeight: FontWeight.w500,
  //         ),
  //       ),
  //       Spacer(),
  //       IconButton(
  //         onPressed: () {
  //           setState(() {
  //             isfavorite = !isfavorite;
  //           });
  //         },
  //         icon: isfavorite ? Icon(Icons.favorite) : Icon(Icons.favorite_border),
  //         color: isfavorite ? Colors.red : Colors.white,
  //       ),
  //     ],
  //   );
  // }
}
