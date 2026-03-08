import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frontend/core/api_client.dart';
import 'package:frontend/models/emotion.dart';
import 'package:frontend/models/mood_color.dart';
import 'package:frontend/models/song_detail.dart';
import 'package:frontend/services/favorite_service.dart';
import 'package:frontend/services/review_service.dart';
import 'package:frontend/services/song_service.dart';
import 'package:frontend/widgets/detail_slider.dart';
import 'package:frontend/widgets/emotion_chip.dart';
import 'package:frontend/widgets/score_card.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:just_audio/just_audio.dart';
import 'package:url_launcher/url_launcher.dart';

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
  Map<String, int> emotionCounts = {};
  double beatValue = 0;
  double lyricValue = 0;
  double moodValue = 0;
  bool _isSubmitting = false;
  bool _isEditingReview = false;
  final TextEditingController _commentController = TextEditingController();

  bool hasMyComment = false;
  bool _loadingEmotion = false;
  List<Emotion> allEmotion = [];
  bool _loadingMoodColor = false;
  List<MoodColor> allMoodColor = [];
  SongDetail? songDetail;
  String myUserName = '';
  int? selectedEmotionId;
  int? selectedMoodColorId;
  Map<String, dynamic> myReview = {};

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _fetchEmotion();
    _fetchMood();
    _fetchDetailSong();
    _getPerfs();
    _audioPlayer.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state.playing;
        });

        if (state.processingState == ProcessingState.completed) {
          _audioPlayer.seek(Duration.zero);
          _audioPlayer.pause();
        }
      }
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _getPerfs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => myUserName = prefs.getString('username') ?? '');
  }

  Color hexToColor(String hex) {
    hex = hex.replaceAll('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  Future<void> _fetchEmotion() async {
    setState(() => _loadingEmotion = true);
    try {
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
    if (!isSilent) setState(() => songDetail = null);
    try {
      final detail = await fetchDetailSong(widget.id);
      if (detail != null) {
        setState(() {
          isfavorite = detail.favorite;
          emotionCounts = Map.from(detail.emotionCounts);
          songDetail = detail;
        });
      }
      await _fetchMyReview();
    } catch (e) {
      debugPrint('Error fetching song detail: $e');
    }
  }

  Future<void> _fetchMyReview() async {
    try {
      final data = await fetchMyReview(widget.id);
      if (data != null) {
        setState(() {
          myReview = data;
          hasMyComment =
              data['comment'] != null &&
              data['comment'].toString().trim().isNotEmpty;
          beatValue = (data['beat_score'] as num).toDouble();
          lyricValue = (data['lyric_score'] as num).toDouble();
          moodValue = (data['mood_score'] as num).toDouble();
          selectedEmotionId = data['emotion_id'];
          if (selectedEmotionId != null && allEmotion.isNotEmpty) {
            final found = allEmotion.firstWhere(
              (e) => e.id == selectedEmotionId,
            );
            selectedEmotion = found.name;
          }
          selectedMoodColorId = data['mood_color_id'];
          if (selectedMoodColorId != null && allMoodColor.isNotEmpty) {
            final found = allMoodColor.firstWhere(
              (m) => m.id == selectedMoodColorId,
            );
            selectedColor = hexToColor(found.colorHex);
          }
          _commentController.text = data['comment'] ?? '';
        });
      } else {
        setState(() {
          myReview = {};
          hasMyComment = false;
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
        hasMyComment = false;
        beatValue = 0;
        lyricValue = 0;
        moodValue = 0;
      });
    }
  }

  Future<void> _submitSharedRating() async {
    if (_isSubmitting) return;
    if (!_isReviewComplete()) {
      _showIncompleteWarning();
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final ok = await submitRating(
        songIdReference: songDetail!.source == 'spotify'
            ? widget.id
            : songDetail!.id.toString(),
        source: songDetail!.source,
        emotionId: selectedEmotionId!,
        moodColorId: selectedMoodColorId!,
        beatScore: beatValue,
        lyricScore: lyricValue,
        moodScore: moodValue,
      );
      if (ok) {
        _showSnack("Rating submitted", Colors.green);
        setState(() => _isEditingReview = false);
        await _fetchDetailSong(isSilent: true);
      } else {
        _showSnack("Something went wrong", Colors.red);
      }
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  Future<void> _updateSharedRating() async {
    bool isDataChanged() =>
        beatValue != myReview['beat_score'] ||
        lyricValue != myReview['lyric_score'] ||
        moodValue != myReview['mood_score'] ||
        selectedEmotionId != myReview['emotion_id'] ||
        selectedMoodColorId != myReview['mood_color_id'];

    if (!isDataChanged()) return;

    final ok = await updateRating(
      reviewId: myReview['id'],
      beatScore: beatValue,
      lyricScore: lyricValue,
      moodScore: moodValue,
      emotionId: selectedEmotionId!,
      moodColorId: selectedMoodColorId!,
    );
    if (ok) {
      _showSnack("Updated Shared Rating", Colors.green);
      setState(() => _isEditingReview = false);
      await _fetchDetailSong(isSilent: true);
    }
  }

  Future<void> _updateComment() async {
    final ok = await editComment(
      reviewId: myReview['id'],
      comment: _commentController.text,
    );
    if (ok) {
      _showSnack("Comment updated", Colors.green);
      await _fetchDetailSong(isSilent: true);
      setState(() {
        openReview = false;
        _commentController.clear();
      });
    }
  }

  Future<void> _deleteComment() async {
    final ok = await deleteComment(myReview['id']);
    if (ok) {
      _showSnack("Comment deleted", Colors.red);
      setState(() {
        myReview['comment'] = null;
        hasMyComment = false;
        openReview = false;
        _commentController.clear();
      });
      await _fetchDetailSong(isSilent: true);
    }
  }

  Future<void> _toggleFavorite() async {
    if (songDetail == null) return;
    final result = await toggleFavorite(
      songIdReference: songDetail!.source == 'spotify'
          ? widget.id
          : songDetail!.id,
      source: songDetail!.source,
    );
    if (result != null) {
      setState(() => isfavorite = result.isFavorited);
      _showSnack(result.message, result.isFavorited ?  Colors.green:const Color.fromARGB(255, 175, 76, 76));
    }
  }

  Future<void> _togglePreview() async {
    if (songDetail?.previewUrl == null) return;

    final playerState = _audioPlayer.playerState;
    final isPlaying = playerState.playing;

    if (isPlaying) {
      await _audioPlayer.pause();
    } else {
      try {
        if (_audioPlayer.audioSource == null ||
            (_audioPlayer.audioSource as UriAudioSource).uri.toString() !=
                songDetail!.previewUrl) {
          await _audioPlayer.setUrl(songDetail!.previewUrl!);
        }
        await _audioPlayer.play();
      } catch (e) {
        debugPrint('Audio error: $e');
      }
    }
  }

  bool _isReviewComplete() =>
      selectedEmotionId != null &&
      selectedMoodColorId != null &&
      beatValue > 0 &&
      lyricValue > 0 &&
      moodValue > 0;

  Future<void> createComment() async {
    if (_commentController.text.trim().isEmpty) return;
    try {
      if (myReview.isEmpty) {
        // ใช้ endpoint ใหม่ที่แยก comment จาก rating
        await _submitCommentStandalone();
      } else if (myReview['comment'] == null) {
        await _submitCommentStandalone();
      } else {
        await _updateComment();
      }
      setState(() {
        openReview = false;
        _commentController.clear();
        hasMyComment = true;
      });
      await _fetchDetailSong(isSilent: true);
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  Future<void> _submitCommentStandalone() async {
    final response = await ApiClient.post('/comment/standalone', {
      "comment": _commentController.text,
      "song_id_reference": songDetail!.source == 'spotify'
          ? widget.id
          : songDetail!.id.toString(),
      "source": songDetail!.source,
    });
    if (response.statusCode == 200) {
      _showSnack("Comment posted", Colors.green);
      await _fetchMyReview(); // reload reviewId ที่เพิ่งสร้าง
    } else {
      _showSnack("Failed to post comment", Colors.red);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showIncompleteWarning() {
    List<String> missing = [];
    if (selectedEmotionId == null) missing.add('Emotion');
    if (selectedMoodColorId == null) missing.add('Color Mood');
    if (beatValue == 0) missing.add('Beat Score');
    if (lyricValue == 0) missing.add('Lyric Score');
    if (moodValue == 0) missing.add('Mood Score');
    final message = missing.isEmpty
        ? 'Please submit your rating first'
        : 'Please complete: ${missing.join(', ')}';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.black),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color.fromARGB(255, 251, 244, 208),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (songDetail == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF0e0e0e),
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0e0e0e),
      body: SafeArea(
        child: Stack(
          children: [
            if (songDetail!.dominantColor != null) ...[
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      hexToColor(songDetail!.dominantColor!),
                      hexToColor(songDetail!.dominantColor!).withOpacity(0.7),
                      hexToColor(songDetail!.dominantColor!).withOpacity(0.2),
                      const Color(0xFF0E0E0E),
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
            ],
            CustomScrollView(
              slivers: [
                SliverAppBar(
                  floating: true,
                  snap: true,
                  backgroundColor: Colors.transparent,
                  leading: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios),
                    color: Colors.white,
                  ),
                  title: Text(
                    songDetail!.songName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  centerTitle: true,
                  actions: [
                    IconButton(
                      onPressed: _toggleFavorite,
                      icon: Icon(
                        isfavorite ? Icons.favorite : Icons.favorite_border,
                      ),
                      color: isfavorite
                          ? const Color.fromARGB(255, 221, 36, 36)
                          : Colors.white,
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
                        _buildRatingSection(),
                        const SizedBox(height: 25),
                        _buildColorMoodSection(),
                        const SizedBox(height: 20),
                        // ─── ปุ่ม Edit / Submit ───
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // ถ้า submit แล้วและไม่ได้ editing — โชว์ปุ่ม Edit
                            if (myReview.isNotEmpty && !_isEditingReview)
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Colors.white38),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                onPressed: () =>
                                    setState(() => _isEditingReview = true),
                                icon: const Icon(Icons.edit_outlined, size: 16),
                                label: const Text(
                                  "Edit",
                                  style: TextStyle(fontSize: 14),
                                ),
                              ),
                            // ถ้ายังไม่ submit หรือกำลัง editing — โชว์ปุ่ม Submit/Save
                            if (myReview.isEmpty || _isEditingReview) ...[
                              if (_isEditingReview)
                                TextButton(
                                  onPressed: () =>
                                      setState(() => _isEditingReview = false),
                                  child: const Text(
                                    "Cancel",
                                    style: TextStyle(color: Colors.white38),
                                  ),
                                ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _isSubmitting
                                      ? Colors.grey
                                      : Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                onPressed: _isSubmitting
                                    ? null
                                    : () => myReview.isEmpty
                                          ? _submitSharedRating()
                                          : _updateSharedRating(),
                                child: _isSubmitting
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          color: Colors.black,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(
                                        myReview.isEmpty
                                            ? "Submit Rating"
                                            : "Save",
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.black,
                                        ),
                                      ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 32),
                        // ─── Divider แยก Rating / Comment ───
                        Row(
                          children: [
                            Expanded(
                              child: Divider(
                                color: Colors.white24,
                                thickness: 1,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              child: Text(
                                "COMMENTS",
                                style: TextStyle(
                                  color: Colors.white38,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(
                                color: Colors.white24,
                                thickness: 1,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildCommentSection(),
                        const SizedBox(height: 60),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMusicCover() {
    debugPrint('link_url : ${songDetail!.linkurl}');
    final raw = songDetail!.image;
    final imageUrl = (raw != null && raw.startsWith('/'))
        ? 'http://10.0.2.2:8000$raw'
        : raw;

    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // ── รูปปก ──
            Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey[900],
                boxShadow: [
                  BoxShadow(
                    color: selectedColor.withOpacity(0.5),
                    blurRadius: 40,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      imageUrl ?? '',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey[800],
                        child: const Center(
                          child: Icon(
                            Icons.music_note,
                            size: 80,
                            color: Colors.white54,
                          ),
                        ),
                      ),
                    ),
                    // overlay มืดตอนเล่น
                    if (_isPlaying)
                      Container(color: Colors.black.withOpacity(0.35)),
                  ],
                ),
              ),
            ),

            // ── Play / Pause button ตรงกลาง ──
            // ── Play / Pause button ตรงกลาง ──
            if (songDetail!.previewUrl != null)
              GestureDetector(
                onTap: _togglePreview,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.55),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _isPlaying
                          ? selectedColor
                          : Colors.white.withOpacity(0.8),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 34,
                  ),
                ),
              ),
          ],
        ),

        if (_isPlaying) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: selectedColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Now Playing',
                style: TextStyle(color: selectedColor, fontSize: 12),
              ),
            ],
          ),
        ],

        const SizedBox(height: 16),

        // ── ชื่อเพลง + ไอคอนลิงก์ ──
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                songDetail!.songName,
                style: const TextStyle(fontSize: 18, color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
            // if (songDetail!.linkurl != null) ...[
            //   const SizedBox(width: 6),
            //   InkWell(
            //     borderRadius: BorderRadius.circular(20),
            //     onTap: () async {
            //       final uri = Uri.parse(songDetail!.linkurl!);
            //       if (await canLaunchUrl(uri)) {
            //         await launchUrl(uri, mode: LaunchMode.externalApplication);
            //       }
            //     },
            //     child: const Icon(
            //       Icons.open_in_new_rounded,
            //       color: Colors.white38,
            //       size: 18,
            //     ),
            //   ),
            // ],
          ],
        ),

        const SizedBox(height: 4),
        Text(
          songDetail!.artistName,
          style: const TextStyle(fontSize: 16, color: Colors.white24),
        ),
      ],
    );
  }

  Widget _buildEmotionsSection() {
    if (_loadingEmotion) {
      return const CircularProgressIndicator(color: Colors.white);
    }
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 10,
      children: allEmotion.map((emotion) {
        return EmotionChip(
          emotion: emotion,
          isSelected: selectedEmotion == emotion.name,
          count: emotionCounts[emotion.name] ?? 0,
          selectedColor: selectedColor,
          onTap: () {
            // lock ถ้า submit แล้วและยังไม่ได้กด Edit
            if (myReview.isNotEmpty && !_isEditingReview) return;
            setState(() {
              if (selectedEmotion == emotion.name) {
                // deselect ได้ตามปกติ
                selectedEmotion = null;
                selectedEmotionId = null;
                emotionCounts[emotion.name] =
                    (emotionCounts[emotion.name] ?? 1) - 1;
              } else {
                if (selectedEmotion != null) {
                  emotionCounts[selectedEmotion!] =
                      (emotionCounts[selectedEmotion!] ?? 1) - 1;
                }
                selectedEmotion = emotion.name;
                selectedEmotionId = emotion.id;
                emotionCounts[emotion.name] =
                    (emotionCounts[emotion.name] ?? 0) + 1;
              }
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildRatingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Music Detail",
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        const SizedBox(height: 10),
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
        const SizedBox(height: 10),
        BuildSlider(
          label: 'Beat',
          color: const Color.fromARGB(255, 229, 206, 107),
          value: beatValue,
          onChanged: (myReview.isNotEmpty && !_isEditingReview)
              ? null
              : (v) => setState(() => beatValue = v),
        ),
        BuildSlider(
          label: 'Lyric',
          color: const Color.fromARGB(255, 236, 123, 123),
          value: lyricValue,
          onChanged: (myReview.isNotEmpty && !_isEditingReview)
              ? null
              : (v) => setState(() => lyricValue = v),
        ),
        BuildSlider(
          label: 'Mood',
          color: Color.fromARGB(173, 150, 81, 184),
          value: moodValue,
          onChanged: (myReview.isNotEmpty && !_isEditingReview)
              ? null
              : (v) => setState(() => moodValue = v),
        ),
      ],
    );
  }

  Widget _buildColorMoodSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Color Mood",
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        const SizedBox(height: 15),
        SizedBox(
          height: 45,
          child: _loadingMoodColor
              ? const CircularProgressIndicator(color: Colors.white)
              : ListView(
                  scrollDirection: Axis.horizontal,
                  children: allMoodColor.map((mood) {
                    final color = hexToColor(mood.colorHex);
                    final count = songDetail?.colorCounts[mood.colorHex] ?? 0;
                    final isSelected = selectedMoodColorId == mood.id;
                    return GestureDetector(
                      onTap: (myReview.isNotEmpty && !_isEditingReview)
                          ? null
                          : () => setState(() {
                              selectedColor = color;
                              selectedMoodColorId = mood.id;
                            }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 10),
                        width: isSelected ? 52 : 45,
                        height: isSelected ? 52 : 45,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(
                            isSelected ? 14 : 10,
                          ),
                          border: Border.all(
                            color: isSelected
                                ? Colors.white
                                : Colors.white.withOpacity(0.2),
                            width: isSelected ? 3 : 1,
                          ),
                        ),
                        child: count > 0
                            ? Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '$count',
                                    style: const TextStyle(
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
                  }).toList(),
                ),
        ),
      ],
    );
  }

  // ─── COMMENT SECTION ──────────────────────────────────────────────────────

  Widget _buildCommentSection() {
    final comments = songDetail!.comment;
    final sortedComments = List.from(comments)
      ..sort(
        (a, b) => DateTime.parse(
          b['created_at'],
        ).compareTo(DateTime.parse(a['created_at'])),
      );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Text(
                  "Comments",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                if (comments.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${comments.length}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            GestureDetector(
              onTap: () {
                setState(() {
                  openReview = !openReview;
                  if (myReview['comment'] != null && openReview) {
                    _commentController.text = myReview['comment'];
                  } else {
                    _commentController.clear();
                  }
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: openReview
                      ? Colors.white
                      : Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      myReview['comment'] != null
                          ? Icons.edit_rounded
                          : Icons.add_rounded,
                      size: 15,
                      color: openReview ? Colors.black : Colors.white,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      myReview['comment'] != null ? "Edit" : "Write",
                      style: TextStyle(
                        color: openReview ? Colors.black : Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        if (openReview) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildAvatar(myUserName, size: 18),
                    const SizedBox(width: 10),
                    Text(
                      myUserName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    if (hasMyComment)
                      GestureDetector(
                        onTap: _showDeleteDialog,
                        child: const Icon(
                          Icons.delete_outline_rounded,
                          color: Colors.redAccent,
                          size: 20,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _commentController,
                  autofocus: true,
                  maxLines: 4,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    height: 1.5,
                  ),
                  decoration: InputDecoration(
                    hintText: "Share your thoughts...",
                    hintStyle: TextStyle(
                      color: Colors.white.withOpacity(0.3),
                      fontSize: 14,
                    ),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => setState(() {
                        openReview = false;
                        _commentController.clear();
                      }),
                      child: const Text(
                        "Cancel",
                        style: TextStyle(color: Colors.white38, fontSize: 13),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 9,
                        ),
                        elevation: 0,
                      ),
                      onPressed: createComment,
                      child: Text(
                        hasMyComment ? "Save" : "Post",
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        if (sortedComments.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.chat_bubble_outline_rounded,
                    color: Colors.white.withOpacity(0.15),
                    size: 40,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "No comments yet",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.3),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: sortedComments.length,
            separatorBuilder: (_, __) =>
                Divider(color: Colors.white.withOpacity(0.06), height: 1),
            itemBuilder: (_, i) {
              final item = sortedComments[i] as Map<String, dynamic>;
              return _buildCommentItem(
                username: item['username'] ?? '',
                text: item['comment'] ?? '',
                createdAt: item['created_at'] ?? '',
              );
            },
          ),
      ],
    );
  }

  Widget _buildCommentItem({
    required String username,
    required String text,
    required String createdAt,
  }) {
    String timeAgo = '';
    try {
      final dt = DateTime.parse(createdAt).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1)
        timeAgo = 'just now';
      else if (diff.inMinutes < 60)
        timeAgo = '${diff.inMinutes}m ago';
      else if (diff.inHours < 24)
        timeAgo = '${diff.inHours}h ago';
      else
        timeAgo = '${diff.inDays}d ago';
    } catch (_) {}

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAvatar(username, size: 16),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      username,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      timeAgo,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.3),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  text,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.75),
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String name, {required double size}) {
    return CircleAvatar(
      radius: size,
      backgroundColor: selectedColor.withOpacity(0.3),
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: TextStyle(
          color: selectedColor,
          fontWeight: FontWeight.w700,
          fontSize: size * 0.8,
        ),
      ),
    );
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          "Delete comment?",
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          "This cannot be undone.",
          style: TextStyle(color: Colors.white54),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Cancel",
              style: TextStyle(color: Colors.white54),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteComment();
            },
            child: const Text(
              "Delete",
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }
}
