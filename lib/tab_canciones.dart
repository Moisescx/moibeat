import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';

class TabCanciones extends StatefulWidget {
  final bool tienePermiso;
  final Future<List<SongModel>>? cancionesFuture;
  final List<SongModel> listaCanciones;
  final Function(int, List<SongModel>)
  onPlay; 
  final Function(SongModel) onLongPress;

  const TabCanciones({
    super.key,
    required this.tienePermiso,
    required this.cancionesFuture,
    required this.listaCanciones,
    required this.onPlay,
    required this.onLongPress,
  });

  @override
  State<TabCanciones> createState() => _TabCancionesState();
}

class _TabCancionesState extends State<TabCanciones> {
  String _textoBusqueda = "";

  @override
  Widget build(BuildContext context) {
    if (!widget.tienePermiso) {
      return const Center(
        child: Text('Necesito permisos para buscar música 😅'),
      );
    }

    return FutureBuilder<List<SongModel>>(
      future: widget.cancionesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.greenAccent),
          );
        }

        if (snapshot.data == null || snapshot.data!.isEmpty) {
          return const Center(
            child: Text('No encontré canciones en tu celular 🎵'),
          );
        }

        final listaBase = widget.listaCanciones.isNotEmpty
            ? widget.listaCanciones
            : snapshot.data!.where((cancion) {
                final duracion = cancion.duration ?? 0;
                final esMusica = cancion.isMusic ?? true;
                final esAlarma = cancion.isAlarm ?? false;
                final esNotificacion = cancion.isNotification ?? false;
                return duracion >= 60000 &&
                    esMusica &&
                    !esAlarma &&
                    !esNotificacion;
              }).toList();

        var cancionesFiltradas = listaBase.where((cancion) {
          return cancion.title.toLowerCase().contains(
                _textoBusqueda.toLowerCase(),
              ) ||
              (cancion.artist?.toLowerCase().contains(
                    _textoBusqueda.toLowerCase(),
                  ) ??
                  false);
        }).toList();

        return ListView.builder(
          itemCount: cancionesFiltradas.isEmpty
              ? 1
              : cancionesFiltradas.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Buscar canción o artista...',
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    filled: true,
                    fillColor: Colors.grey[800],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                  onChanged: (valor) {
                    setState(() {
                      _textoBusqueda = valor;
                    });
                  },
                ),
              );
            }

            if (cancionesFiltradas.isEmpty) {
              return const Padding(
                padding: EdgeInsets.only(top: 40.0),
                child: Center(child: Text('No encontré esa canción 🕵️‍♂️')),
              );
            }

            var cancion = cancionesFiltradas[index - 1];
            int indiceOriginal = listaBase.indexOf(cancion);

            return Container(
              margin: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 55,
                    height: 55,
                    child: QueryArtworkWidget(
                      id: cancion.id,
                      type: ArtworkType.AUDIO,
                      artworkBorder: BorderRadius.zero,
                      nullArtworkWidget: Container(
                        color: Colors.grey[800],
                        child: const Icon(
                          Icons.music_note,
                          size: 30,
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
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    cancion.artist ?? "Artista desconocido",
                    style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                  ),
                ),
                trailing: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey.withValues(alpha: 0.1),
                  ),
                  child: const Icon(Icons.play_arrow_rounded, size: 20),
                ),
                onTap: () {
                  widget.onPlay(indiceOriginal, listaBase);
                },
                onLongPress: () {
                  widget.onLongPress(cancion);
                },
              ),
            );
          },
        );
      },
    );
  }
}
