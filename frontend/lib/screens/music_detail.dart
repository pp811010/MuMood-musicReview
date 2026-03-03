import 'package:flutter/material.dart';
import 'package:frontend/models/comment.dart';
import 'package:frontend/models/music.dart';

class MusicDetail extends StatefulWidget {
  final Music music;
  const MusicDetail({super.key, required this.music});

  @override
  State<MusicDetail> createState() => _MusicDetailState();
}

class _MusicDetailState extends State<MusicDetail> {
  bool isfavorite = false;
  Color selectedColor = Colors.purple;
  String? selectedEmotion;
  bool openReview = false;
  Map<String, int> emotionCounts = {
    "เศร้า": 12,
    "รัก": 8,
    "เหงา": 25,
    "คิดถึง": 15,
    "อกหัก": 30,
  };
  double bassValue = 2.50;
  double midValue = 4;
  double trebleValue = 4;
  int meId = 10;
  // ignore: prefer_final_fields
  late TextEditingController _commentController = TextEditingController();
  final List<Comment> allComment = [
    Comment(
      id: 1,
      ownerId: 2,
      ownerImage:
          "https://cdn.mos.cms.futurecdn.net/whowhatwear/posts/248024/end-of-the-fucking-world-jessica-barden-interview-248024-1517177858159-square.jpg",
      ownername: "God Girl",
      comment: "good sound same angel voice",
    ),
    Comment(
      id: 2,
      ownerId: 3,
      ownerImage:
          "https://www.billboard.com/wp-content/uploads/media/end-of-the-fucking-world-netflix-2018-billboard-1548.jpg",
      ownername: "Alex Turner",
      comment: "This song hits different at 3 AM. Pure masterpiece! 🎵",
    ),
    Comment(
      id: 3,
      ownerId: 4,
      ownerImage:
          "https://i.pinimg.com/736x/a4/32/45/a43245d7c790db43e0c6d5b8b158f54c.jpg",
      ownername: "MusicLover",
      comment: "Can't stop listening to this. The melody is so addictive!",
    ),
    Comment(
      id: 4,
      ownerId: 5,
      ownerImage:
          "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRPFq5BvYrfLVHqVxJfPvRf5o9fPsVmN7eGbA&s",
      ownername: "SoundSeeker",
      comment: "เพลงนี้ทำให้รู้สึกถึงอารมณ์ได้ลึกมาก ชอบบีทและเนื้อร้องมากๆ",
    ),
    Comment(
      id: 5,
      ownerId: 6,
      ownerImage:
          "https://i.pinimg.com/originals/72/d3/7a/72d37a66c611ec60c5b9a57c9e8bc9bb.jpg",
      ownername: "NightOwl",
      comment: "Perfect for late night vibes. Been on repeat all week! 🌙✨",
    ),
  ];
  bool hasMyComment = false;
  Comment? myComment;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void createComment() {
    if (_commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Please enter your comment before submitting."),
          backgroundColor: const Color.fromARGB(255, 0, 0, 0),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (myComment == null) {
      myComment = Comment(
        id: allComment.length + 1,
        ownerId: meId,
        ownerImage:
            "https://cms.dmpcdn.com/dara/2020/12/14/e449fab0-3dc4-11eb-9b6d-3fdf37c2e48e_original.jpg",
        ownername: "พระรามควงปืน",
        comment: _commentController.text,
      );
      setState(() {
        allComment.add(myComment!);
        hasMyComment = true;
        openReview = false;
        _commentController.clear();
      });
    } else {
      setState(() {
        int index = allComment.indexWhere((c) => c.id == myComment!.id);
        if (index != -1) {
          allComment[index] = Comment(
            id: myComment!.id,
            ownerId: myComment!.ownerId,
            ownerImage: myComment!.ownerImage,
            ownername: myComment!.ownername,
            comment: _commentController.text,
          );
          myComment = allComment[index];
        }
        openReview = false;
        _commentController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0e0e0e),
      body: SafeArea(
        child: Stack(
          children: [
            Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFFFFA23E),
                        Color(0xFFFF7A18),
                        Color(0xFF1A0F08),
                        Color(0xFF0E0E0E),
                      ],
                      stops: [0.2, 0.3, 0.7, 1.0],
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
                CustomScrollView(
                  slivers: [
                    SliverAppBar(
                      pinned: true,
                      backgroundColor:  Color(0xFFFFA23E),
                      leading: IconButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        icon: Icon(Icons.arrow_back_ios),
                        color: Colors.white,
                      ),
                      title: Text(
                        widget.music.title,
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
                            setState(() {
                              isfavorite = !isfavorite;
                            });
                          },
                          icon: isfavorite
                              ? Icon(Icons.favorite)
                              : Icon(Icons.favorite_border),
                          color: isfavorite ? Colors.red : Colors.white,
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
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                "Music Detail",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                            _buildEQSlider(
                              'Beat',
                              const Color.fromARGB(255, 104, 228, 106),
                              bassValue,
                              (value) {
                                setState(() => bassValue = value);
                              },
                            ),
                            _buildEQSlider(
                              'Lyric',
                              const Color.fromARGB(255, 166, 1, 1),
                              midValue,
                              (value) {
                                setState(() => midValue = value);
                              },
                            ),
                            _buildEQSlider(
                              'Mood',
                              const Color.fromARGB(174, 109, 3, 162),
                              trebleValue,
                              (value) {
                                setState(() => trebleValue = value);
                              },
                            ),
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
                              child: ListView(
                                scrollDirection: Axis.horizontal,
                                children: [
                                  _buildColorOption(
                                    const Color.fromARGB(214, 18, 24, 18),
                                  ),
                                  _buildColorOption(
                                    const Color.fromARGB(255, 65, 46, 18),
                                  ),
                                  _buildColorOption(
                                    const Color.fromARGB(255, 4, 87, 66),
                                  ),
                                  _buildColorOption(Colors.purple),
                                  _buildColorOption(Colors.blue),
                                  _buildColorOption(
                                    const Color.fromARGB(255, 212, 14, 0),
                                  ),
                                  _buildColorOption(Colors.green),
                                  _buildColorOption(Colors.lime),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color.fromARGB(
                                    255,
                                    254,
                                    255,
                                    255,
                                  ),
                                ),
                                onPressed: () {},
                                child: Text(
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
                    if (hasMyComment  && openReview) {
                      _commentController.text = myComment!.comment;
                    } else {
                      _commentController.clear();
                    }
                  });
                },
                style: ButtonStyle(
                  maximumSize: WidgetStatePropertyAll(Size(80, 40)),
                ),
                child: Text(
                  hasMyComment ? "Edit" : "Review",
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
                "พระราม ควงปืน",
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
                                allComment.removeWhere(
                                  (c) => c.id == myComment!.id,
                                );
                                myComment = null;
                                hasMyComment = false;
                                openReview = false;
                                _commentController.clear();
                              });
                              Navigator.pop(context);

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("Comment deleted successfully"),
                                  backgroundColor: Colors.green,
                                  behavior: SnackBarBehavior.floating,
                                  duration: Duration(seconds: 2),
                                ),
                              );
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

  Widget _buildCommentCard(Comment comment) {
    bool isMyComment = comment.ownerId == meId;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 15, vertical: 25),
      decoration: BoxDecoration(
        color: isMyComment ? selectedColor : Color.fromARGB(139, 45, 45, 45),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 19,
                backgroundImage: NetworkImage(comment.ownerImage),
              ),
              SizedBox(width: 13),
              Text(
                comment.ownername,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 15),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              comment.comment,
              style: TextStyle(color: Colors.white, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllComment() {
    List<Comment> sortedComments = List.from(allComment)
      ..sort((a, b) => b.id.compareTo(a.id));
    return ListView.separated(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      separatorBuilder: (context, index) => SizedBox(height: 15),
      itemCount: sortedComments.length,
      itemBuilder: (context, index) {
        return _buildCommentCard(sortedComments[index]);
      },
    );
  }

  Widget _buildColorOption(Color color) {
    final bool isSelected = selectedColor == color;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedColor = color;
        });
      },
      child: Container(
        width: 45,
        decoration: BoxDecoration(
          color: color,
          border: isSelected ? Border.all(color: Colors.white, width: 3) : null,
        ),
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
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 20,
      children: [
        _buildEmotionIcon(Icons.sentiment_very_dissatisfied, "Sad"),
        _buildEmotionIcon(Icons.favorite, "Love"),
        _buildEmotionIcon(Icons.nightlight_round, "Lonely"),
        _buildEmotionIcon(Icons.psychology, "Missing"),
        _buildEmotionIcon(Icons.heart_broken, "Heartbroken"),
      ],
    );
  }

  Widget _buildEmotionIcon(IconData icon, String emotion) {
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
                  widget.music.image,
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
          widget.music.title,
          style: TextStyle(fontSize: 18, color: Colors.white),
        ),
        Text(
          widget.music.artist,
          style: TextStyle(fontSize: 18, color: Colors.white24),
        ),
      ],
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(Icons.arrow_back_ios),
          color: Colors.white,
        ),
        Spacer(),
        Text(
          widget.music.title,
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        Spacer(),
        IconButton(
          onPressed: () {
            setState(() {
              isfavorite = !isfavorite;
            });
          },
          icon: isfavorite ? Icon(Icons.favorite) : Icon(Icons.favorite_border),
          color: isfavorite ? Colors.red : Colors.white,
        ),
      ],
    );
  }
}
