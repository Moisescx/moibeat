import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SongOptionsSheet extends StatelessWidget {
  final SongModel cancion;
  final List<String> playlists;

  const SongOptionsSheet({
    super.key,
    required this.cancion,
    required this.playlists,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Agregar '${cancion.title}' a...",
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 20),
          if (playlists.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                "Primero debes crear una playlist en la pestaña 'Playlists'",
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            ..._buildPlaylistItems(context),
        ],
      ),
    );
  }

  List<Widget> _buildPlaylistItems(BuildContext context) {
    return playlists.map((nombrePlaylist) {
      return ListTile(
        leading: const Icon(
          Icons.queue_music,
          color: Colors.greenAccent,
        ),
        title: Text(
          nombrePlaylist,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
        onTap: () async {
          final prefs = await SharedPreferences.getInstance();
          List<String> cancionesDeEstaPlaylist =
              prefs.getStringList('canciones_de_$nombrePlaylist') ?? [];

          String idCancion = cancion.id.toString();

          if (!cancionesDeEstaPlaylist.contains(idCancion)) {
            cancionesDeEstaPlaylist.add(idCancion);
            await prefs.setStringList(
              'canciones_de_$nombrePlaylist',
              cancionesDeEstaPlaylist,
            );

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Agregada a $nombrePlaylist',
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  backgroundColor: Colors.greenAccent,
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          } else {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Esta canción ya está en la playlist'),
                  duration: Duration(seconds: 2),
                ),
              );
            }
          }

          if (context.mounted) {
            Navigator.pop(context);
          }
        },
      );
    }).toList();
  }
}
