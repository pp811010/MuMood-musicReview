import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frontend/core/api_client.dart';
import 'package:frontend/models/emotion.dart';
import 'package:frontend/models/mood_color.dart';
import 'package:frontend/models/song_detail.dart';
import 'package:frontend/services/comment_service.dart';
import 'package:frontend/services/favorite_service.dart';
import 'package:frontend/services/review_service.dart';
import 'package:frontend/services/song_service.dart';
import 'package:frontend/widgets/color_mood_section.dart';
import 'package:frontend/widgets/comment_section.dart';
import 'package:frontend/widgets/emotion_section.dart';
import 'package:frontend/widgets/music_cover.dart';
import 'package:frontend/widgets/rating_section.dart';
import 'package:frontend/widgets/review_action_button.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:just_audio/just_audio.dart';

class SongDetailPage extends StatefulWidget {
  final String id;
  const SongDetailPage({super.key, required this.id});

  @override
  State<SongDetailPage> createState() => _MusicDetailState();
}

class _MusicDetailState extends State<SongDetailPage> {
  bool isfavorite = false;
  Color selectedColor = Colors.purple;
  String? selectedEmotion;
  Map<String, int> emotionCounts = {};
  double beatValue = 0;
  double lyricValue = 0;
  double moodValue = 0;
  bool _isSubmitting = false;
  bool _isEditingReview = false;
  int? selectedEmotionId;
  int? selectedMoodColorId;
  Map<String, dynamic> myReview = {};

  bool _openCommentBox = false;
  bool _isPostingComment = false;
  int? _editingCommentId;
  final TextEditingController _commentController = TextEditingController();
  List<CommentItem> _comments = [];
  int _myUserId = 0;

  bool _loadingEmotion = false;
  List<Emotion> allEmotion = [];
  bool _loadingMoodColor = false;
  List<MoodColor> allMoodColor = [];
  SongDetail? songDetail;
  String myUserName = '';

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _fetchEmotion();
    _fetchMood();
    _fetchDetailSong();
    _getPrefs();
    _audioPlayer.playerStateStream.listen((state) {
      if (mounted) {
        setState(() => _isPlaying = state.playing);
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

  void _getPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      myUserName = prefs.getString('username') ?? '';
      _myUserId = prefs.getInt('user_id') ?? 0;
    });
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
      await Future.wait([_fetchMyReview(), _fetchComments()]);
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
        });
      } else {
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

  Future<void> _fetchComments() async {
    if (songDetail == null) return;
    try {
      final songIdInt = int.tryParse(songDetail!.id.toString());
      if (songIdInt == null) return;
      final comments = await fetchCommentsBySong(songIdInt);
      setState(() => _comments = comments);
    } catch (e) {
      debugPrint('Error fetching comments: $e');
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

    if (!isDataChanged()) {
      setState(() => _isEditingReview = false);
      return;
    }
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

  void _openNewComment() {
    setState(() {
      _openCommentBox = true;
      _editingCommentId = null;
      _commentController.clear();
    });
  }

  void _startEditComment(CommentItem comment) {
    setState(() {
      _openCommentBox = true;
      _editingCommentId = comment.id;
      _commentController.text = comment.content;
    });
  }

  void _closeCommentBox() {
    setState(() {
      _openCommentBox = false;
      _editingCommentId = null;
      _commentController.clear();
    });
  }

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    setState(() => _isPostingComment = true);
    try {
      if (_editingCommentId != null) {
        final ok = await updateComment(
          commentId: _editingCommentId!,
          content: text,
        );
        if (ok) {
          _showSnack("Comment updated", Colors.green);
          _closeCommentBox();
          await _fetchComments();
        } else {
          _showSnack("Failed to update comment", Colors.red);
        }
      } else {
        final songRef = songDetail!.source == 'spotify'
            ? widget.id
            : songDetail!.id.toString();
        final result = await postComment(
          songIdReference: songRef,
          source: songDetail!.source,
          content: text,
        );
        if (result != null) {
          _showSnack("Comment posted", Colors.green);
          _closeCommentBox();
          await _fetchComments();
        } else {
          _showSnack("Failed to post comment", Colors.red);
        }
      }
    } finally {
      setState(() => _isPostingComment = false);
    }
  }

  Future<void> _deleteComment(int commentId) async {
    final ok = await deleteComment(commentId);
    if (ok) {
      _showSnack("Comment deleted", Colors.redAccent);
      setState(() => _comments.removeWhere((c) => c.id == commentId));
    } else {
      _showSnack("Failed to delete comment", Colors.red);
    }
  }

  void _showDeleteCommentDialog(CommentItem comment) {
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
              await _deleteComment(comment.id);
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

  // ── Other actions ──────────────────────────────────────────────────────────

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
      _showSnack(
        result.message,
        result.isFavorited
            ? Colors.green
            : const Color.fromARGB(255, 175, 76, 76),
      );
    }
  }

  Future<void> _togglePreview() async {
    if (songDetail?.previewUrl == null) return;
    final isPlaying = _audioPlayer.playerState.playing;
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

    final bool isLocked = myReview.isNotEmpty && !_isEditingReview;
    final String? rawImage = songDetail!.image;
    final String? imageUrl = (rawImage != null && rawImage.startsWith('/'))
        ? 'http://10.0.2.2:8000$rawImage'
        : rawImage;

    return Scaffold(
      backgroundColor: const Color(0xFF0e0e0e),
      body: SafeArea(
        child: Stack(
          children: [
            // ── Background gradient ──
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
                // ── AppBar ──
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
                        MusicCoverWidget(
                          songName: songDetail!.songName,
                          artistName: songDetail!.artistName,
                          imageUrl: imageUrl,
                          previewUrl: songDetail!.previewUrl,
                          isPlaying: _isPlaying,
                          selectedColor: selectedColor,
                          onTogglePreview: _togglePreview,
                        ),
                        const SizedBox(height: 30),
                        EmotionSection(
                          isLoading: _loadingEmotion,
                          allEmotion: allEmotion,
                          selectedEmotion: selectedEmotion,
                          emotionCounts: emotionCounts,
                          selectedColor: selectedColor,
                          isLocked: isLocked,
                          onTap: (emotion) {
                            setState(() {
                              if (selectedEmotion == emotion.name) {
                                selectedEmotion = null;
                                selectedEmotionId = null;
                                emotionCounts[emotion.name] =
                                    (emotionCounts[emotion.name] ?? 1) - 1;
                              } else {
                                if (selectedEmotion != null) {
                                  emotionCounts[selectedEmotion!] =
                                      (emotionCounts[selectedEmotion!] ?? 1) -
                                      1;
                                }
                                selectedEmotion = emotion.name;
                                selectedEmotionId = emotion.id;
                                emotionCounts[emotion.name] =
                                    (emotionCounts[emotion.name] ?? 0) + 1;
                              }
                            });
                          },
                        ),
                        const SizedBox(height: 30),
                        RatingSection(
                          avgScores: songDetail!.avgScores,
                          beatValue: beatValue,
                          lyricValue: lyricValue,
                          moodValue: moodValue,
                          isLocked: isLocked,
                          onBeatChanged: (v) => setState(() => beatValue = v),
                          onLyricChanged: (v) => setState(() => lyricValue = v),
                          onMoodChanged: (v) => setState(() => moodValue = v),
                        ),
                        const SizedBox(height: 25),

                        ColorMoodSection(
                          isLoading: _loadingMoodColor,
                          allMoodColor: allMoodColor,
                          selectedMoodColorId: selectedMoodColorId,
                          colorCounts: songDetail!.colorCounts,
                          isLocked: isLocked,
                          onSelect: (mood, color) => setState(() {
                            selectedColor = color;
                            selectedMoodColorId = mood.id;
                          }),
                        ),
                        const SizedBox(height: 20),

                        ReviewActionButtons(
                          hasReview: myReview.isNotEmpty,
                          isEditing: _isEditingReview,
                          isSubmitting: _isSubmitting,
                          onEdit: () => setState(() => _isEditingReview = true),
                          onCancel: () =>
                              setState(() => _isEditingReview = false),
                          onSubmit: myReview.isEmpty
                              ? _submitSharedRating
                              : _updateSharedRating,
                        ),
                        const SizedBox(height: 32),

                        Row(
                          children: [
                            const Expanded(
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
                            const Expanded(
                              child: Divider(
                                color: Colors.white24,
                                thickness: 1,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        CommentSection(
                          comments: _comments,
                          myUserId: _myUserId,
                          myUserName: myUserName,
                          selectedColor: selectedColor,
                          openCommentBox: _openCommentBox,
                          isEditingComment: _editingCommentId != null,
                          isPosting: _isPostingComment,
                          controller: _commentController,
                          onOpenNew: _openNewComment,
                          onCloseBox: _closeCommentBox,
                          onSubmit: _submitComment,
                          onEditComment: _startEditComment,
                          onDeleteComment: _showDeleteCommentDialog,
                        ),
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
}
