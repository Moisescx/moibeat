import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TabFavoritos extends StatefulWidget {
  final List<SongModel> listaCanciones;
  final ValueNotifier<List<String>> notificadorFavoritos;
  final Function(int, List<SongModel>) onPlay;

  const TabFavoritos({
    super.key,
    required this.listaCanciones,
    required this.notificadorFavoritos,
    required this.onPlay,
  });

  @override
  State<TabFavoritos> createState() => _TabFavoritosState();
}

class _TabFavoritosState extends State<TabFavoritos> {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<String>>(
      valueListenable: widget.notificadorFavoritos,
      builder: (context, listaFavoritos, child) {
        List<SongModel> cancionesFavoritas = widget.listaCanciones
            .where((cancion) => listaFavoritos.contains(cancion.id.toString()))
            .toList();

        if (cancionesFavoritas.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.favorite_border_rounded,
                  size: 80,
                  color: Colors.grey[800],
                ),
                const SizedBox(height: 16),
                Text(
                  "Aún no tienes favoritas",
                  style: TextStyle(color: Colors.grey[500], fontSize: 18),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: cancionesFavoritas.length,
          itemBuilder: (context, index) {
            var cancion = cancionesFavoritas[index];
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
                      child: const Icon(Icons.music_note, color: Colors.grey),
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
              trailing: IconButton(
                icon: const Icon(
                  Icons.favorite_rounded,
                  color: Colors.greenAccent,
                  size: 20,
                ),
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  List<String> nuevaLista = List.from(listaFavoritos);
                  nuevaLista.remove(cancion.id.toString());
                  widget.notificadorFavoritos.value = nuevaLista;
                  await prefs.setStringList('mis_favoritas', nuevaLista);
                },
              ),
              onTap: () {
                widget.onPlay(index, cancionesFavoritas);
              },
            );
          },
        );
      },
    );
  }
}
