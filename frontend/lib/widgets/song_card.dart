import 'package:flutter/material.dart';
import 'package:frontend/models/music.dart';
import 'package:frontend/screens/user/song_detail_page.dart';

class SongCard extends StatelessWidget {
  final Music music;
  final double? width;

  SongCard({super.key, required this.music, this.width});

  @override
  Widget build(BuildContext context) {

    // final imageUrl = music.image.startsWith('/') 
    //   ? 'http://10.0.2.2:8000${music.image}' 
    //   : music.image;
  

    return SizedBox(
      width: width,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (context) => SongDetailPage(id: music.id.toString()),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.network(
                  music.image.isNotEmpty
                      ? music.image
                      : "https://via.placeholder.com/150",
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: double.infinity,
                      height: double.infinity,
                      color: const Color(0xFF1E1E1E),
                      child: const Center(
                        child: Icon(
                          Icons.music_note,
                          size: 50,
                          color: Colors.white24,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),

            Text(
              music.title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              music.artist,
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
