import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';

class PlaylistDetailSheet extends StatelessWidget {
  final String nombrePlaylist;
  final List<SongModel> cancionesDeEstaPlaylist;
  final Function(int, List<SongModel>) onSongTap;

  const PlaylistDetailSheet({
    super.key,
    required this.nombrePlaylist,
    required this.cancionesDeEstaPlaylist,
    required this.onSongTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey[600],
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              color: Colors.grey[850],
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: cancionesDeEstaPlaylist.isNotEmpty
                  ? QueryArtworkWidget(
                      id: cancionesDeEstaPlaylist.first.id,
                      type: ArtworkType.AUDIO,
                      artworkBorder: BorderRadius.zero,
                      size: 500,
                      nullArtworkWidget: const Icon(
                        Icons.music_note,
                        size: 80,
                        color: Colors.grey,
                      ),
                    )
                  : const Icon(
                      Icons.queue_music,
                      size: 80,
                      color: Colors.grey,
                    ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            nombrePlaylist,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          Text(
            "${cancionesDeEstaPlaylist.length} canciones",
            style: const TextStyle(fontSize: 16, color: Colors.greenAccent),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: cancionesDeEstaPlaylist.isEmpty
                ? Center(
                    child: Text(
                      "Aún no has agregado canciones aquí",
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  )
                : ListView.builder(
                    itemCount: cancionesDeEstaPlaylist.length,
                    itemBuilder: (context, index) {
                      var cancion = cancionesDeEstaPlaylist[index];
                      return ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: SizedBox(
                            width: 45,
                            height: 45,
                            child: QueryArtworkWidget(
                              id: cancion.id,
                              type: ArtworkType.AUDIO,
                              nullArtworkWidget: Container(
                                color: Colors.grey[800],
                                child: const Icon(
                                  Icons.music_note,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ),
                        ),
                        title: Text(
                          cancion.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                        ),
                        subtitle: Text(
                          cancion.artist ?? "Desconocido",
                          maxLines: 1,
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
                        ),
                        onTap: () {
                          onSongTap(index, cancionesDeEstaPlaylist);
                          Navigator.pop(context);
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
