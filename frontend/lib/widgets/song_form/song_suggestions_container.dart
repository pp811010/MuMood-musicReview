import 'package:flutter/material.dart';

class SongSuggestionsContainer extends StatelessWidget {
  final String type;
  final List<Map<String, dynamic>> songObjects;
  final List<String> suggestedArtists;
  final List<String> suggestedAlbums;
  final void Function({
    required String name,
    required String artist,
    required String album,
  }) onSongSelected;
  final void Function(String value) onArtistSelected;
  final void Function(String value) onAlbumSelected;

  const SongSuggestionsContainer({
    super.key,
    required this.type,
    required this.songObjects,
    required this.suggestedArtists,
    required this.suggestedAlbums,
    required this.onSongSelected,
    required this.onArtistSelected,
    required this.onAlbumSelected,
  });

  List<dynamic> get _suggestions {
    if (type == 'song') return songObjects;
    if (type == 'artist') return suggestedArtists;
    return suggestedAlbums;
  }

  @override
  Widget build(BuildContext context) {
    if (_suggestions.isEmpty) return const SizedBox.shrink();

    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2C),
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)],
      ),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: _suggestions.length,
        itemBuilder: (context, index) {
          final item = _suggestions[index];
          final String displayLabel =
              type == 'song' ? item['display'] : item.toString();

          return ListTile(
            title: Text(
              displayLabel,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
            onTap: () {
              if (type == 'song') {
                onSongSelected(
                  name: item['name'],
                  artist: item['artist'],
                  album: item['album'],
                );
              } else if (type == 'artist') {
                onArtistSelected(item);
              } else {
                onAlbumSelected(item);
              }
              FocusScope.of(context).unfocus();
            },
          );
        },
      ),
    );
  }
}
