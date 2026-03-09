import 'package:flutter/material.dart';
import 'package:frontend/models/music.dart';
import 'package:frontend/screens/user/song_detail.dart';

class SongCard extends StatelessWidget {
  final Music music;
  final double? width;

  SongCard({super.key, required this.music, this.width});

  @override
  Widget build(BuildContext context) {

    final imageUrl = music.image.startsWith('/') 
      ? 'http://10.0.2.2:8000${music.image}' 
      : music.image;
  

    return SizedBox(
      width: width,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (context) => MusicDetail(id: music.id.toString()),
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
                  imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
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
