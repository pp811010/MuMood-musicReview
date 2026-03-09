import 'package:flutter/material.dart';
import 'package:frontend/screens/user/song_detail_page.dart';
import 'package:frontend/widgets/no_tracks_found.dart';
import 'package:frontend/widgets/tranding_list_shimmer.dart';

class TrendingList extends StatelessWidget {
  final List<Map<String, String>> trendingSongs;
  final bool isLoading;

  const TrendingList({
    super.key,
    required this.trendingSongs,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    debugPrint('--- Trending Songs Data ---');
    for (var song in trendingSongs) {
      debugPrint('ID: ${song['id']}, Title: ${song['title']}');
    }
    debugPrint('---------------------------');

    if (isLoading) {
      return TrendingListShimmer(itemCount: 5);
    }
    if (isLoading) {
      return TrendingListShimmer(itemCount: 5);
    }

    if (trendingSongs.isEmpty) {
      return const NoTracksFound();
    }

    return Padding(
      padding: const EdgeInsets.only(left: 10),
      child: SizedBox(
        height: 220,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: trendingSongs.length,
          itemBuilder: (context, index) {
            final song = trendingSongs[index];
            return Container(
              width: 150,
              margin: const EdgeInsets.only(right: 15),
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (context) =>
                          SongDetailPage(id: song['id'].toString()),
                    ),
                  );
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Image.network(
                        song['image']!,
                        height: 150,
                        width: 150,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          print('Image error: $error');
                          return Container(
                            height: 150,
                            width: 150,
                            color: Colors.grey[800],
                            child: const Icon(
                              Icons.music_note,
                              color: Colors.white38,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      song['title']!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      song['artist']!,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
