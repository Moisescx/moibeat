import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';

class ArtistSongsSheet extends StatelessWidget {
  final ArtistModel artista;
  final OnAudioQuery audioQuery;
  final Function(int, List<SongModel>) onSongTap;

  const ArtistSongsSheet({
    super.key,
    required this.artista,
    required this.audioQuery,
    required this.onSongTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            "Canciones de ${artista.artist}",
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.greenAccent,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: FutureBuilder<List<SongModel>>(
              future: audioQuery.queryAudiosFrom(
                AudiosFromType.ARTIST_ID,
                artista.id,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Colors.greenAccent,
                    ),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text(
                      'No hay canciones 😅',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                var cancionesDelArtista = snapshot.data!;

                return ListView.builder(
                  itemCount: cancionesDelArtista.length,
                  itemBuilder: (context, index) {
                    var cancion = cancionesDelArtista[index];
                    return ListTile(
                      leading: const Icon(
                        Icons.music_note,
                        color: Colors.grey,
                      ),
                      title: Text(
                        cancion.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                      ),
                      onTap: () {
                        onSongTap(index, cancionesDelArtista);
                        Navigator.pop(context);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
